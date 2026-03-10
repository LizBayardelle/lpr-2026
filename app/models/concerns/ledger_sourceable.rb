module LedgerSourceable
  extend ActiveSupport::Concern

  included do
    has_many :loan_ledger_entries, as: :source, dependent: :nullify
    before_destroy :reverse_ledger_entries
  end

  private

  def reverse_ledger_entries
    service = LoanLedger::PostingService.new(loan)
    loan_ledger_entries.not_reversed.find_each do |entry|
      service.reverse!(entry, reason: "Source record deleted")
    end
  end
end
