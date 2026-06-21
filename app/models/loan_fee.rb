class LoanFee < ApplicationRecord
  include LedgerSourceable

  belongs_to :loan

  validates :fee_type, presence: true, inclusion: { in: %w[late_fee extension modification inspection legal other] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :fee_date, presence: true

  scope :unpaid, -> { where(paid: false) }
  scope :paid, -> { where(paid: true) }
  scope :recent, -> { order(fee_date: :desc) }
  scope :pertaining_to_period, ->(period_start, period_end) { where(pertains_to_month: period_start.beginning_of_month..period_end) }

  before_validation :default_pertains_to_month
  after_create_commit :post_to_ledger
  after_update_commit :sync_pertains_to_ledger, if: :saved_change_to_pertains_to_month?

  def mark_paid!
    update!(paid: true)
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "fee_paid",
      effective_date: Date.current,
      pertains_to_month: pertains_to_month,
      amount: -amount,
      description: "#{fee_type.titleize} fee paid",
      source: self
    })
  end

  private

  def default_pertains_to_month
    self.pertains_to_month ||= fee_date&.beginning_of_month
  end

  def sync_pertains_to_ledger
    loan_ledger_entries.update_all(pertains_to_month: pertains_to_month)
  end

  def post_to_ledger
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "fee_assessed",
      effective_date: fee_date,
      pertains_to_month: pertains_to_month,
      amount: amount,
      description: "#{fee_type.titleize} fee assessed",
      source: self
    })
  end
end
