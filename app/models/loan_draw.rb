class LoanDraw < ApplicationRecord
  include LedgerSourceable

  belongs_to :loan

  validates :draw_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending approved funded rejected] }

  scope :funded, -> { where(status: "funded") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(draw_date: :desc) }
  scope :pertaining_to_period, ->(period_start, period_end) { where(pertains_to_month: period_start.beginning_of_month..period_end) }

  before_validation :default_pertains_to_month
  after_update_commit :sync_pertains_to_ledger, if: :saved_change_to_pertains_to_month?

  def fund!
    update!(status: "funded")
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "draw",
      effective_date: draw_date,
      pertains_to_month: pertains_to_month,
      amount: amount,
      description: "Draw funded#{description.present? ? ": #{description}" : ""}",
      source: self
    })
  end

  def reject!
    update!(status: "rejected")
  end

  def approve!
    update!(status: "approved")
  end

  private

  def default_pertains_to_month
    self.pertains_to_month ||= draw_date&.beginning_of_month
  end

  def sync_pertains_to_ledger
    loan_ledger_entries.update_all(pertains_to_month: pertains_to_month)
  end
end
