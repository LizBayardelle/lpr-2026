class Client::LoanStatementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_loan
  before_action :set_statement

  def show
    respond_to do |format|
      format.html do
        @period_payments = @loan.payments.for_period(@statement.period_start, @statement.period_end).order(:payment_date)
        @period_draws = @loan.loan_draws.funded.where(draw_date: @statement.period_start..@statement.period_end).order(:draw_date)
        @period_fees = @loan.loan_fees.where(fee_date: @statement.period_start..@statement.period_end).order(:fee_date)
      end
      format.pdf do
        pdf_data = StatementPdf.new(@statement).render
        filename = "statement-#{@loan.borrower_name.parameterize}-#{@statement.period_end.strftime('%Y-%m')}.pdf"
        send_data pdf_data, filename: filename, type: "application/pdf", disposition: "inline"
      end
    end
  end

  private

  def set_loan
    email_loan_ids = Loan.where(borrower_email: current_user.email).select(:id)
    role_loan_ids = current_user.loans.select(:id)
    @loan = Loan.where(id: email_loan_ids).or(Loan.where(id: role_loan_ids)).find(params[:loan_id])
  end

  def set_statement
    @statement = @loan.loan_statements.find(params[:id])
  end
end
