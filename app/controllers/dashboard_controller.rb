class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    email = current_user.email

    # Loans where the borrower email matches this user
    @loans = Loan.where(borrower_email: email).order(origination_date: :desc)

    # Statements across all their loans, most recent first
    @statements = LoanStatement.where(loan_id: @loans.select(:id)).order(statement_date: :desc).limit(10)

    # Their uploaded documents
    @uploads = ClientUpload.where(client_email: email).recent.limit(10)

    # Quick stats
    @active_loans_count = @loans.where(status: "active").count
    @pending_uploads_count = @uploads.select(&:pending?).count
  end
end
