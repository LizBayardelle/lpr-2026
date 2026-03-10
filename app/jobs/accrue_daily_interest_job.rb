class AccrueDailyInterestJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    Loan.active.find_each do |loan|
      accrue_for_loan(loan, date)
    end
  end

  private

  def accrue_for_loan(loan, date)
    # Idempotent: skip if already accrued for this date
    return if loan.loan_ledger_entries.where(entry_type: "interest_accrual", effective_date: date).exists?

    balance = loan.current_balance
    return if balance <= 0

    daily = loan.daily_interest(balance)
    return if daily <= 0

    LoanLedger::PostingService.new(loan).post!({
      entry_type: "interest_accrual",
      effective_date: date,
      amount: daily,
      description: "Daily interest accrual",
      metadata: {
        balance: balance.to_f,
        rate: loan.effective_interest_rate.to_f,
        calc_method: loan.interest_calc_method
      }
    })
  end
end
