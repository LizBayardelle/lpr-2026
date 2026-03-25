class Client::LoansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_loan

  def show
    @payments = @loan.payments.recent
    @statements = @loan.loan_statements.recent
    @documents = @loan.loan_documents
  end

  private

  def set_loan
    # Only allow access to loans the user is associated with
    email_loan_ids = Loan.where(borrower_email: current_user.email).select(:id)
    role_loan_ids = current_user.loans.select(:id)
    @loan = Loan.where(id: email_loan_ids).or(Loan.where(id: role_loan_ids)).find(params[:id])
  end
end
