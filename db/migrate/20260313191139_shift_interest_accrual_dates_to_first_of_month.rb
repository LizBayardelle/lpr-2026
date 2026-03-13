class ShiftInterestAccrualDatesToFirstOfMonth < ActiveRecord::Migration[8.0]
  def up
    LoanLedgerEntry.where(entry_type: "interest_accrual").find_each do |entry|
      old_date = entry.effective_date
      # Only shift month-end dated accruals (skip any already on 1st)
      next unless old_date == old_date.end_of_month

      new_date = old_date + 1.day # 1st of next month
      period_end = old_date
      period_start = period_end.beginning_of_month
      metadata = (entry.metadata || {}).merge(
        "period_start" => period_start.to_s,
        "period_end" => period_end.to_s
      )
      entry.update_columns(effective_date: new_date, metadata: metadata)
    end

    # Rebalance all loans with interest accruals
    loan_ids = LoanLedgerEntry.where(entry_type: "interest_accrual").distinct.pluck(:loan_id)
    loan_ids.each do |loan_id|
      loan = Loan.find(loan_id)
      LoanLedger::PostingService.new(loan).rebalance!
    end
  end

  def down
    LoanLedgerEntry.where(entry_type: "interest_accrual").find_each do |entry|
      old_date = entry.effective_date
      # Only shift 1st-of-month dated accruals back to month-end
      next unless old_date.day == 1

      new_date = old_date - 1.day # Back to month-end
      entry.update_columns(effective_date: new_date)
    end

    loan_ids = LoanLedgerEntry.where(entry_type: "interest_accrual").distinct.pluck(:loan_id)
    loan_ids.each do |loan_id|
      loan = Loan.find(loan_id)
      LoanLedger::PostingService.new(loan).rebalance!
    end
  end
end
