class LoanFee < ApplicationRecord
  include LedgerSourceable

  belongs_to :loan

  validates :fee_type, presence: true, inclusion: { in: %w[late_fee extension modification inspection legal other] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :fee_date, presence: true

  scope :unpaid, -> { where(paid: false) }
  scope :paid, -> { where(paid: true) }
  scope :recent, -> { order(fee_date: :desc) }

  after_create_commit :post_to_ledger

  def mark_paid!
    update!(paid: true)
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "fee_paid",
      effective_date: Date.current,
      amount: -amount,
      description: "#{fee_type.titleize} fee paid",
      source: self
    })
  end

  private

  def post_to_ledger
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "fee_assessed",
      effective_date: fee_date,
      amount: amount,
      description: "#{fee_type.titleize} fee assessed",
      source: self
    })
  end
end
