class Admin::LoansController < Admin::BaseController
  before_action :set_loan, only: [:show, :edit, :update, :destroy, :generate_statement]

  def index
    @loans = Loan.order(created_at: :desc)
    @loans = @loans.where(status: params[:status]) if params[:status].present?
  end

  def show
    @loan.accrue_interest_if_needed
    LoanLedger::PostingService.new(@loan).rebalance!
    @ledger_sort = params[:ledger_sort] == "desc" ? "desc" : "asc"
    @ledger_entries = @ledger_sort == "asc" ? @loan.loan_ledger_entries.chronological : @loan.loan_ledger_entries.reverse_chronological

    # Build a hash of entry_id => principal balance at that point (for monthly interest column)
    principal = BigDecimal("0")
    @principal_at_entry = {}
    @loan.loan_ledger_entries.chronological.each do |entry|
      principal += entry.amount if entry.principal_affecting?
      @principal_at_entry[entry.id] = principal
    end
    last_accrual_date = @loan.loan_ledger_entries.where(entry_type: "interest_accrual").maximum(:effective_date)
    @next_accrual_month = if last_accrual_date
      # Accruals are dated 1st of the month after the period, so the next period
      # to accrue starts on that same date (e.g., last accrual Aug 1 = July done, next = Aug 1-31)
      last_accrual_date.beginning_of_month
    else
      @loan.origination_date.beginning_of_month
    end

    @payments = @loan.payments.recent
    @statements = @loan.loan_statements.includes(:statement_sends).recent
    @draws = @loan.loan_draws.recent
    @fees = @loan.loan_fees.recent
    @extensions = @loan.loan_extensions.order(created_at: :desc)
    @reserves = @loan.loan_reserves.order(created_at: :desc)
    @documents = @loan.loan_documents
  end

  def new
    @loan = Loan.new(
      origination_date: Date.current,
      payment_type: "interest_only",
      interest_calc_method: "30_360",
      late_fee_percent: 5.0,
      grace_period_days: 10
    )
  end

  def create
    @loan = Loan.new(loan_params)
    if @loan.save
      create_reserve_if_requested(@loan)
      redirect_to admin_loan_path(@loan), notice: "Loan created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @loan.update(loan_params)
      redirect_to admin_loan_path(@loan), notice: "Loan updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @loan.destroy
    redirect_to admin_loans_path, notice: "Loan deleted."
  end

  def generate_statement
    if params[:period_start].present? && params[:period_end].present?
      # Custom date range
      period_start = params[:period_start].to_date
      period_end = params[:period_end].to_date
      statement = LoanStatement.generate_for_loan(@loan, period_end, period_start: period_start, period_end: period_end)
    elsif params[:month].present? && params[:year].present?
      date = Date.new(params[:year].to_i, params[:month].to_i, 1)
      statement = LoanStatement.generate_for_loan(@loan, date)
    else
      statement = LoanStatement.generate_for_loan(@loan)
    end

    if statement.persisted?
      redirect_to admin_loan_loan_statement_path(@loan, statement), notice: "Statement generated for #{statement.period_start.strftime('%b %-d')} – #{statement.period_end.strftime('%b %-d, %Y')}."
    else
      redirect_to admin_loan_path(@loan, tab: "statements"), alert: "Could not generate statement."
    end
  end

  private

  def set_loan
    @loan = Loan.find(params[:id])
  end

  def create_reserve_if_requested(loan, source: nil)
    return unless params[:reserve_amount].present? && params[:reserve_amount].to_d > 0

    loan.loan_reserves.create!(
      amount: params[:reserve_amount].to_d,
      reserve_type: params[:reserve_type].presence || "interest",
      established_date: source&.respond_to?(:created_at) ? Date.current : loan.origination_date,
      source: source || loan,
      notes: params[:reserve_notes]
    )
  end

  def loan_params
    params.require(:loan).permit(
      :borrower_name, :borrower_email, :borrower_phone, :borrower_address,
      :property_address, :loan_amount, :interest_rate, :loan_term_months,
      :origination_fee_percent, :origination_fee_flat, :origination_fee_type, :origination_fee_handling,
      :payment_type, :interest_calc_method,
      :origination_date, :maturity_date, :first_payment_date,
      :default_interest_rate, :late_fee_percent, :grace_period_days,
      :status, :notes
    )
  end
end
