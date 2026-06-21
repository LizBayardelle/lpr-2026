class Payment < ApplicationRecord
  include LedgerSourceable

  belongs_to :loan
  belongs_to :loan_reserve, optional: true

  # A split-payment cash payment auto-generates a "reserve draw" payment for the
  # portion covered by the reserve. These link the two so editing/deleting the
  # cash payment keeps its reserve draw correct.
  belongs_to :reserve_draw_for, class_name: "Payment", optional: true
  has_one :reserve_draw, class_name: "Payment", foreign_key: :reserve_draw_for_id, dependent: :destroy

  attr_accessor :skip_ledger_posting

  # True for the auto-generated reserve draw that compensates a split payment.
  # These are managed entirely through their parent cash payment — they must not
  # be edited or deleted directly, or they'd drift out of sync. (A manual reserve
  # draw from the Reserves tab has loan_reserve_id but no reserve_draw_for_id and
  # is NOT one of these.)
  def auto_reserve_draw?
    reserve_draw_for_id.present?
  end

  validates :payment_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: %w[check wire ach cash other] }, allow_blank: true

  scope :recent, -> { order(payment_date: :desc) }
  scope :for_period, ->(start_date, end_date) { where(payment_date: start_date..end_date) }
  # Payments whose pertaining-month falls within the statement period. A payment
  # received in May but marked as pertaining to April lands on April's statement.
  scope :pertaining_to_period, ->(period_start, period_end) { where(pertains_to_month: period_start.beginning_of_month..period_end) }

  # Fields that change what the payment posts to the ledger.
  LEDGER_FIELDS = %w[amount interest_amount principal_amount late_fee_amount payment_date].freeze

  before_validation :allocate_payment, on: :create
  before_validation :default_pertains_to_month
  after_create_commit :post_to_ledger, unless: :skip_ledger_posting
  after_update_commit :resync_ledger_entries, if: :ledger_amounts_changed?
  after_update_commit :sync_pertains_to_ledger, if: -> { saved_change_to_pertains_to_month? && !ledger_amounts_changed? }
  # Keep the source reserve's status (active/depleted) correct as draws change.
  after_commit :refresh_reserve_status, on: [:create, :update, :destroy]
  # Auto-create/keep-in-sync the reserve draw that compensates a split payment.
  # (Deletes are handled by the has_one :reserve_draw dependent: :destroy above.)
  after_create_commit :create_reserve_compensation, unless: :skip_ledger_posting
  after_update_commit :sync_reserve_compensation

  private

  # A "primary" payment is a real cash payment that a reserve draw compensates —
  # i.e. not itself a reserve draw, and on a split-payment loan.
  def primary_split_payment?
    loan_reserve_id.nil? && reserve_draw_for_id.nil? && loan.split_payment?
  end

  # The reserve draw this payment currently has, fetched fresh (the has_one
  # association can be cached stale across the create/update callbacks).
  def current_reserve_draw
    Payment.find_by(reserve_draw_for_id: id)
  end

  # The reserve should top the cash payment up to the full scheduled payment,
  # clamped to ≥ 0 and to what the reserve can actually provide.
  def desired_reserve_compensation(existing_draw)
    reserve = loan.auto_draw_reserve
    return [BigDecimal("0"), nil] unless reserve

    gap = loan.monthly_payment_amount - amount.to_d
    gap = BigDecimal("0") if gap < 0
    available = reserve.remaining_balance + (existing_draw&.amount || 0)
    [[gap, available].min, reserve]
  end

  def create_reserve_compensation
    return unless primary_split_payment?

    desired, reserve = desired_reserve_compensation(nil)
    return if reserve.nil? || desired <= 0

    loan.payments.create!(
      payment_date: payment_date,
      pertains_to_month: pertains_to_month,
      amount: desired,
      loan_reserve: reserve,
      reserve_draw_for: self,
      notes: "Auto-draw: reserve portion of #{payment_date.strftime('%b %Y')} payment"
    )
  end

  # On edit, recompute the existing reserve draw (resize, re-date, or remove it).
  # Only touches a draw that already exists — never creates one on edit.
  def sync_reserve_compensation
    return unless primary_split_payment?
    draw = current_reserve_draw
    return unless draw

    desired, = desired_reserve_compensation(draw)
    if desired <= 0
      draw.destroy
    elsif draw.amount != desired || draw.payment_date != payment_date || draw.pertains_to_month != pertains_to_month
      draw.update!(amount: desired, payment_date: payment_date, pertains_to_month: pertains_to_month)
    end
  end

  def default_pertains_to_month
    self.pertains_to_month ||= payment_date&.beginning_of_month
  end

  def ledger_amounts_changed?
    return false if skip_ledger_posting
    (saved_changes.keys & LEDGER_FIELDS).any?
  end

  # When a payment's amounts or date change, rebuild its ledger entries from the
  # current values and recompute balances/accruals — so everything derived from
  # the ledger (current balance, principal-as-of, interest accrual) stays correct.
  def resync_ledger_entries
    loan_ledger_entries.destroy_all
    post_to_ledger
    LoanLedger::PostingService.new(loan).rebalance!
  end

  # Keep the payment's ledger entries on the same statement month as the payment.
  def sync_pertains_to_ledger
    loan_ledger_entries.update_all(pertains_to_month: pertains_to_month)
  end

  def refresh_reserve_status
    LoanReserve.find_by(id: loan_reserve_id)&.recompute_status! if loan_reserve_id
  end

  def allocate_payment
    return if loan.nil? || amount.blank?
    return if interest_amount.present? && interest_amount > 0

    interest_owed = loan.monthly_interest_due
    self.interest_amount = [amount, interest_owed].min
    self.principal_amount = [amount - interest_amount, 0].max
  end

  def post_to_ledger
    service = LoanLedger::PostingService.new(loan)
    entries = []
    reserve_suffix = reserve_description_suffix

    if interest_amount.to_d > 0
      entries << { entry_type: "payment_interest", effective_date: payment_date, pertains_to_month: pertains_to_month,
                   amount: -interest_amount, description: "Interest payment#{reserve_suffix}", source: self }
    end

    if principal_amount.to_d > 0
      entries << { entry_type: "payment_principal", effective_date: payment_date, pertains_to_month: pertains_to_month,
                   amount: -principal_amount, description: "Principal payment#{reserve_suffix}", source: self }
    end

    if late_fee_amount.to_d > 0
      entries << { entry_type: "payment_late_fee", effective_date: payment_date, pertains_to_month: pertains_to_month,
                   amount: -late_fee_amount, description: "Late fee payment#{reserve_suffix}", source: self }
    end

    service.post!(entries) if entries.any?
  end

  def reserve_description_suffix
    return "" unless loan_reserve

    drawn = ActionController::Base.helpers.number_to_currency(amount)
    remaining = ActionController::Base.helpers.number_to_currency(loan_reserve.remaining_balance)
    " (#{drawn} drawn from reserve, #{remaining} remains)"
  end
end
