module LoanLedger
  class PostingService
    def initialize(loan, posted_by: nil)
      @loan = loan
      @posted_by = posted_by
    end

    # Post one or more entries atomically. Accepts a hash or array of hashes.
    # Automatically rebalances if any entry is backdated before existing entries.
    def post!(entries_attrs)
      entries_attrs = Array.wrap(entries_attrs)

      created = LoanLedgerEntry.transaction do
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

      # Rebalance if any posted entry falls before the latest existing entry,
      # which means chronological order changed and interest accruals may need recalculation.
      latest_existing = @loan.loan_ledger_entries.where.not(id: created.map(&:id)).maximum(:effective_date)
      if latest_existing && created.any? { |e| e.effective_date < latest_existing }
        rebalance!
      end

      created
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

    # Recalculate all running balances and interest accrual amounts in chronological order.
    # Call after posting entries with backdated effective_dates or editing existing entries.
    def rebalance!
      LoanLedgerEntry.transaction do
        @loan.loan_ledger_entries.lock("FOR UPDATE").first # lock
        running = BigDecimal("0")
        principal = BigDecimal("0")

        @loan.loan_ledger_entries.order(:effective_date, :id).each do |entry|
          # Recalculate interest accrual amounts based on principal at that point
          if entry.entry_type == "interest_accrual" && !entry.reversed? && !entry.reversal?
            period_start = entry.metadata&.dig("period_start")&.to_date
            period_end = entry.metadata&.dig("period_end")&.to_date

            # Fall back: infer period from effective_date (1st of month = prior month's interest)
            if period_end.nil?
              if entry.effective_date.day == 1
                period_end = entry.effective_date - 1.day
                period_start ||= period_end.beginning_of_month
              else
                period_end = entry.effective_date.end_of_month
                period_start ||= entry.effective_date.beginning_of_month
              end
            end
            period_start ||= period_end.beginning_of_month

            if principal > 0
              days = (period_end - period_start).to_i + 1
              new_amount = @loan.monthly_interest_for_period(principal, days, period_end, period_start: period_start)
              if new_amount != entry.amount
                entry.update_columns(
                  amount: new_amount,
                  metadata: (entry.metadata || {}).merge(
                    "balance" => principal.to_f,
                    "period_start" => period_start.to_s,
                    "period_end" => period_end.to_s
                  )
                )
                entry.reload
              end
            end
          end

          principal += entry.amount if entry.principal_affecting?
          running += entry.amount if entry.balance_affecting?
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
