class LoanReserve < ApplicationRecord
  belongs_to :loan
  belongs_to :source, polymorphic: true, optional: true
  has_many :payments
  has_many :loan_ledger_entries, as: :source, dependent: :nullify

  RESERVE_TYPES = %w[interest debt_service holdback].freeze
  STATUSES = %w[active depleted released forfeited].freeze

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :reserve_type, inclusion: { in: RESERVE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :established_date, presence: true

  scope :active, -> { where(status: "active") }

  after_create_commit :post_withholding_to_ledger
  after_update_commit :sync_withholding_ledger_entry, if: :saved_change_to_amount?

  def remaining_balance
    amount - payments.sum(:amount)
  end

  def depleted?
    remaining_balance <= 0
  end

  def draw!(payment_attrs)
    draw_amount = payment_attrs[:amount].to_d
    raise "Draw amount exceeds reserve balance (#{remaining_balance})" if draw_amount > remaining_balance

    payment = nil
    ActiveRecord::Base.transaction do
      payment = loan.payments.create!(
        payment_date: payment_attrs[:payment_date] || Date.current,
        amount: draw_amount,
        notes: payment_attrs[:notes] || "Reserve draw - #{reserve_type.titleize}",
        loan_reserve: self
      )
      update!(status: "depleted") if remaining_balance <= 0
    end
    payment
  end

  def release!
    ActiveRecord::Base.transaction do
      update!(status: "released")
      post_release_to_ledger("Reserve released — #{remaining_balance_before_status_change} returned to borrower")
    end
  end

  def forfeit!
    ActiveRecord::Base.transaction do
      update!(status: "forfeited")
      post_release_to_ledger("Reserve forfeited — #{remaining_balance_before_status_change} retained by lender")
    end
  end

  def display_type
    reserve_type.titleize
  end

  def display_name
    name.presence || "#{display_type} Reserve"
  end

  private

  def post_withholding_to_ledger
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "reserve_withholding",
      effective_date: established_date,
      amount: amount,
      description: withholding_description,
      source: self
    })
  end

  def sync_withholding_ledger_entry
    entry = loan_ledger_entries.where(entry_type: "reserve_withholding").not_reversed.first
    return unless entry

    entry.update!(amount: amount, description: withholding_description)
  end

  def withholding_description
    "#{display_type} reserve established — #{ActionController::Base.helpers.number_to_currency(amount)}"
  end

  def post_release_to_ledger(description)
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "reserve_release",
      effective_date: Date.current,
      amount: amount,
      description: description,
      source: self
    })
  end

  def remaining_balance_before_status_change
    ActionController::Base.helpers.number_to_currency(amount - payments.sum(:amount))
  end
end
