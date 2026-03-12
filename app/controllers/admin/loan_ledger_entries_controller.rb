class Admin::LoanLedgerEntriesController < Admin::BaseController
  before_action :set_loan
  before_action :set_entry, only: [:reverse, :destroy]

  def create
    service = LoanLedger::PostingService.new(@loan, posted_by: current_user)
    service.post!({
      entry_type: "adjustment",
      effective_date: params[:effective_date].to_date,
      amount: params[:amount].to_d,
      description: params[:description]
    })
    redirect_to ledger_path, notice: "Adjustment posted."
  rescue => e
    redirect_to ledger_path, alert: "Could not post adjustment: #{e.message}"
  end

  def accrue_interest
    period_start = params[:period_start].to_date
    period_end = params[:period_end].to_date

    if period_end <= period_start
      redirect_to ledger_path, alert: "Period end must be after period start."
      return
    end

    actual_days = (period_end - period_start).to_i + 1
    display_days = @loan.interest_calc_method == "30_360" ? @loan.calc_30_360_days(period_start, period_end) : actual_days
    balance = @loan.principal_balance_as_of(period_start)

    if balance <= 0
      redirect_to ledger_path, alert: "No principal balance as of #{period_start}."
      return
    end

    interest = @loan.monthly_interest_for_period(balance, actual_days, period_end, period_start: period_start)

    service = LoanLedger::PostingService.new(@loan, posted_by: current_user)
    service.post!({
      entry_type: "interest_accrual",
      effective_date: period_end,
      amount: interest,
      description: "Interest accrual - #{period_start.strftime('%b %-d, %Y')} to #{period_end.strftime('%b %-d, %Y')}",
      metadata: {
        balance: balance.to_f,
        rate: @loan.effective_interest_rate.to_f,
        calc_method: @loan.interest_calc_method,
        days: display_days
      }
    })

    redirect_to ledger_path, notice: "Interest accrual of #{ActionController::Base.helpers.number_to_currency(interest)} posted (#{display_days} days on #{ActionController::Base.helpers.number_to_currency(balance)} balance)."
  rescue => e
    redirect_to ledger_path, alert: "Could not post interest accrual: #{e.message}"
  end

  def reverse
    service = LoanLedger::PostingService.new(@loan, posted_by: current_user)
    service.reverse!(@entry, reason: params[:reason].presence || "Admin reversal")
    redirect_to ledger_path, notice: "Entry reversed."
  rescue => e
    redirect_to ledger_path, alert: "Could not reverse entry: #{e.message}"
  end

  def destroy
    unless current_user.godpowers?
      redirect_to ledger_path, alert: "Only godpowers users can delete ledger entries."
      return
    end

    @entry.destroy!
    LoanLedger::PostingService.new(@loan).rebalance!
    redirect_to ledger_path, notice: "Entry ##{@entry.id} deleted and balances recalculated."
  rescue => e
    redirect_to ledger_path, alert: "Could not delete entry: #{e.message}"
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_entry
    @entry = @loan.loan_ledger_entries.find(params[:id])
  end

  def ledger_path
    admin_loan_path(@loan, tab: "ledger", ledger_sort: params[:ledger_sort])
  end
end
