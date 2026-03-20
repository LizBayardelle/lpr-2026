class Payment < ApplicationRecord
  include LedgerSourceable

  belongs_to :loan
  belongs_to :loan_reserve, optional: true

  attr_accessor :skip_ledger_posting

  validates :payment_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: %w[check wire ach cash other] }, allow_blank: true

  scope :recent, -> { order(payment_date: :desc) }
  scope :for_period, ->(start_date, end_date) { where(payment_date: start_date..end_date) }

  before_validation :allocate_payment, on: :create
  after_create_commit :post_to_ledger, unless: :skip_ledger_posting

  private

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
      entries << { entry_type: "payment_interest", effective_date: payment_date,
                   amount: -interest_amount, description: "Interest payment#{reserve_suffix}", source: self }
    end

    if principal_amount.to_d > 0
      entries << { entry_type: "payment_principal", effective_date: payment_date,
                   amount: -principal_amount, description: "Principal payment#{reserve_suffix}", source: self }
    end

    if late_fee_amount.to_d > 0
      entries << { entry_type: "payment_late_fee", effective_date: payment_date,
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
