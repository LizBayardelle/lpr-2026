class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    email = current_user.email

    # Loans where the borrower email matches this user OR they have a loan_role
    email_loan_ids = Loan.where(borrower_email: email).select(:id)
    role_loan_ids = current_user.loans.select(:id)
    @loans = Loan.where(id: email_loan_ids).or(Loan.where(id: role_loan_ids)).order(origination_date: :desc)

    # Statements across all their loans, most recent first
    @statements = LoanStatement.where(loan_id: @loans.select(:id)).order(statement_date: :desc).limit(10)

    # Their uploaded documents
    @uploads = ClientUpload.where(client_email: email).recent.limit(10)

    # Quick stats
    active_loans = @loans.where(status: "active")
    @active_loans_count = active_loans.count
    @total_balance = active_loans.sum { |l| l.current_balance }
    @next_payment = active_loans.min_by(&:next_payment_date)
    @pending_uploads_count = @uploads.select(&:pending?).count
  end
end
