module LedgerSourceable
  extend ActiveSupport::Concern

  included do
    # Deleting the source removes its ledger entries outright, then balances and
    # interest accruals are recomputed — so the record's impact is fully undone
    # (rather than left as today-dated reversals that mis-time historical interest).
    has_many :loan_ledger_entries, as: :source, dependent: :destroy
    after_destroy_commit :rebalance_ledger_after_removal
  end

  private

  def rebalance_ledger_after_removal
    LoanLedger::PostingService.new(loan).rebalance!
  end
end
