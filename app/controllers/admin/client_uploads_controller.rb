class Admin::ClientUploadsController < Admin::BaseController
  before_action :set_upload, only: [:show, :assign, :reject]

  def index
    @status = params[:status].presence || "pending"
    @uploads = ClientUpload.recent
    @uploads = @uploads.where(status: @status) if ClientUpload::STATUSES.include?(@status)
    @loans = Loan.order(:borrower_name) if @status == "pending"
    @pending_count = ClientUpload.pending.count
  end

  def show
    @loans = Loan.order(:borrower_name)
  end

  def assign
    loan = Loan.find(params[:loan_id])
    @upload.assign_to_loan!(loan, current_user)
    redirect_to admin_client_uploads_path, notice: "Document assigned to #{loan.borrower_name}'s loan."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_client_uploads_path, alert: "Could not assign document: #{e.message}"
  end

  def reject
    @upload.update!(status: "rejected")
    redirect_to admin_client_uploads_path, notice: "Upload marked as rejected."
  end

  private

  def set_upload
    @upload = ClientUpload.find(params[:id])
  end
end
