class LoanDraw < ApplicationRecord
  include LedgerSourceable

  belongs_to :loan

  validates :draw_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending approved funded rejected] }

  scope :funded, -> { where(status: "funded") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(draw_date: :desc) }

  def fund!
    update!(status: "funded")
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "draw",
      effective_date: draw_date,
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
end
