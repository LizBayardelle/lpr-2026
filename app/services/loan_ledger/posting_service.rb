module LoanLedger
  class PostingService
    def initialize(loan, posted_by: nil)
      @loan = loan
      @posted_by = posted_by
    end

    # Post one or more entries atomically. Accepts a hash or array of hashes.
    def post!(entries_attrs)
      entries_attrs = Array.wrap(entries_attrs)

      LoanLedgerEntry.transaction do
        last_entry = @loan.loan_ledger_entries.order(id: :desc).lock("FOR UPDATE").first
        current_balance = last_entry&.running_balance || BigDecimal("0")

        entries_attrs.map do |attrs|
          delta = balance_delta(attrs[:entry_type], attrs[:amount])
          current_balance += delta

          @loan.loan_ledger_entries.create!(
            entry_type: attrs[:entry_type],
            effective_date: attrs[:effective_date],
            amount: attrs[:amount],
            running_balance: current_balance,
            description: attrs[:description],
            source: attrs[:source],
            posted_by: @posted_by,
            reversal_of_id: attrs[:reversal_of_id],
            metadata: attrs[:metadata] || {}
          )
        end
      end
    end

    # Reverse an existing entry
    def reverse!(entry, reason: "Reversal")
      post!({
        entry_type: entry.entry_type,
        effective_date: Date.current,
        amount: -entry.amount,
        description: "#{reason}: reversal of ##{entry.id}",
        source: entry.source,
        reversal_of_id: entry.id
      }).tap do |reversal_entries|
        entry.update_column(:reversed_by_id, reversal_entries.first.id)
      end
    end

    # Recalculate all running balances in chronological order.
    # Call after posting entries with backdated effective_dates.
    def rebalance!
      LoanLedgerEntry.transaction do
        @loan.loan_ledger_entries.lock("FOR UPDATE").first # lock
        running = BigDecimal("0")
        @loan.loan_ledger_entries.order(:effective_date, :id).each do |entry|
          running += entry.amount
          entry.update_column(:running_balance, running) if entry.running_balance != running
        end
      end
    end

    private

    def balance_delta(entry_type, amount)
      if LoanLedgerEntry::BALANCE_AFFECTING_TYPES.include?(entry_type)
        amount
      else
        BigDecimal("0")
      end
    end
  end
end
