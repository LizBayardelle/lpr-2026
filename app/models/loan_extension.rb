class LoanExtension < ApplicationRecord
  belongs_to :loan
  has_many :loan_ledger_entries, as: :source, dependent: :nullify

  validates :original_maturity_date, presence: true
  validates :new_maturity_date, presence: true
  validate :new_date_after_original

  after_create :update_loan_status
  after_create_commit :post_extension_fee_to_ledger

  private

  def new_date_after_original
    return unless original_maturity_date && new_maturity_date
    if new_maturity_date <= original_maturity_date
      errors.add(:new_maturity_date, "must be after the original maturity date")
    end
  end

  def update_loan_status
    loan.update!(status: "extended")
  end

  def post_extension_fee_to_ledger
    return unless extension_fee.to_d > 0
    LoanLedger::PostingService.new(loan).post!({
      entry_type: "extension_fee",
      effective_date: Date.current,
      amount: extension_fee,
      description: "Extension fee",
      source: self
    })
  end
end
