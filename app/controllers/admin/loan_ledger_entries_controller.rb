class Admin::LoanLedgerEntriesController < Admin::BaseController
  before_action :set_loan
  before_action :set_entry, only: [:reverse, :destroy, :update]

  def index
    render json: { entries: entries_json }
  end

  def create
    entry_type = params[:entry_type] || (params[:principal_affecting] == "1" ? "adjustment_principal" : "adjustment")
    service = LoanLedger::PostingService.new(@loan, posted_by: current_user)
    amount = params[:amount].to_d
    effective_date = params[:effective_date].to_date
    description = params[:description]

    entries = if entry_type == "payment_interest" && amount < 0
      split_interest_payment(amount, effective_date, description)
    else
      [{ entry_type: entry_type, effective_date: effective_date,
         amount: amount, description: description }]
    end

    service.post!(entries)

    respond_to do |format|
      format.json { render json: { entries: entries_json } }
      format.html { redirect_to ledger_path, notice: "Adjustment posted." }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to ledger_path, alert: "Could not post adjustment: #{e.message}" }
    end
  end

  def accrue_interest
    period_start = params[:period_start].to_date
    period_end = params[:period_end].to_date

    if period_end <= period_start
      respond_to do |format|
        format.json { render json: { error: "Period end must be after period start." }, status: :unprocessable_entity }
        format.html { redirect_to ledger_path, alert: "Period end must be after period start." }
      end
      return
    end

    actual_days = (period_end - period_start).to_i + 1
    display_days = @loan.interest_calc_method == "30_360" ? @loan.calc_30_360_days(period_start, period_end) : actual_days
    balance = @loan.principal_balance_as_of(period_start)

    if balance <= 0
      respond_to do |format|
        format.json { render json: { error: "No principal balance as of #{period_start}." }, status: :unprocessable_entity }
        format.html { redirect_to ledger_path, alert: "No principal balance as of #{period_start}." }
      end
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

    notice = "Interest accrual of #{ActionController::Base.helpers.number_to_currency(interest)} posted (#{display_days} days on #{ActionController::Base.helpers.number_to_currency(balance)} balance)."
    respond_to do |format|
      format.json { render json: { entries: entries_json, notice: notice } }
      format.html { redirect_to ledger_path, notice: notice }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to ledger_path, alert: "Could not post interest accrual: #{e.message}" }
    end
  end

  def update
    attrs = {}
    attrs[:effective_date] = params[:effective_date].to_date if params[:effective_date].present?
    attrs[:description] = params[:description] if params.key?(:description)
    attrs[:amount] = params[:amount].to_d if params.key?(:amount)

    @entry.update!(attrs)

    if attrs[:effective_date] || attrs[:amount]
      LoanLedger::PostingService.new(@loan).rebalance!
    end

    respond_to do |format|
      format.json { render json: { entries: entries_json } }
      format.html { head :ok }
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def reverse
    service = LoanLedger::PostingService.new(@loan, posted_by: current_user)
    service.reverse!(@entry, reason: params[:reason].presence || "Admin reversal")

    respond_to do |format|
      format.json { render json: { entries: entries_json } }
      format.html { redirect_to ledger_path, notice: "Entry reversed." }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to ledger_path, alert: "Could not reverse entry: #{e.message}" }
    end
  end

  def destroy
    unless current_user.godpowers?
      respond_to do |format|
        format.json { render json: { error: "Only godpowers users can delete ledger entries." }, status: :forbidden }
        format.html { redirect_to ledger_path, alert: "Only godpowers users can delete ledger entries." }
      end
      return
    end

    @entry.destroy!
    LoanLedger::PostingService.new(@loan).rebalance!

    respond_to do |format|
      format.json { render json: { entries: entries_json } }
      format.html { redirect_to ledger_path, notice: "Entry ##{@entry.id} deleted and balances recalculated." }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to ledger_path, alert: "Could not delete entry: #{e.message}" }
    end
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_entry
    @entry = @loan.loan_ledger_entries.find(params[:id])
  end

  # Auto-split a payment_interest entry: if the payment exceeds outstanding
  # interest, the excess is applied as payment_principal so that interest
  # accrual correctly reflects the reduced principal balance.
  def split_interest_payment(amount, effective_date, description)
    accrued = @loan.loan_ledger_entries
      .where(entry_type: "interest_accrual")
      .where("effective_date <= ?", effective_date).sum(:amount)
    paid = @loan.loan_ledger_entries
      .where(entry_type: "payment_interest")
      .where("effective_date <= ?", effective_date).sum(:amount)
    outstanding_interest = [accrued + paid, BigDecimal("0")].max

    payment_abs = amount.abs
    interest_portion = [payment_abs, outstanding_interest].min
    principal_portion = payment_abs - interest_portion

    entries = []
    if interest_portion > 0
      entries << { entry_type: "payment_interest", effective_date: effective_date,
                   amount: -interest_portion, description: description.presence || "Interest payment" }
    end
    if principal_portion > 0
      entries << { entry_type: "payment_principal", effective_date: effective_date,
                   amount: -principal_portion, description: "Principal payment" }
    end
    entries.presence || [{ entry_type: "payment_interest", effective_date: effective_date,
                           amount: amount, description: description }]
  end

  def ledger_path
    admin_loan_path(@loan, tab: "ledger", ledger_sort: params[:ledger_sort])
  end

  def entries_json
    @loan.loan_ledger_entries.chronological.map do |e|
      {
        id: e.id,
        entryType: e.entry_type,
        effectiveDate: e.effective_date.to_s,
        amount: e.amount.to_s,
        runningBalance: e.running_balance.to_s,
        description: e.description,
        reversedById: e.reversed_by_id,
        reversalOfId: e.reversal_of_id,
      }
    end
  end
end
