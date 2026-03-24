class Admin::ClientUploadsController < Admin::BaseController
  before_action :set_upload, only: [:show, :assign, :reject]

  def index
    @status = params[:status].presence || "pending"
    @uploads = ClientUpload.includes(:loan, :assigned_by_user, file_attachment: :blob).recent
    @uploads = @uploads.where(status: @status) if ClientUpload::STATUSES.include?(@status)
    @uploads = @uploads.where("client_name ILIKE :q OR client_email ILIKE :q", q: "%#{params[:client]}%") if params[:client].present?
    @uploads = @uploads.where(loan_id: params[:loan_id]) if params[:loan_id].present?
    @uploads = @uploads.where(document_type: params[:doc_type]) if params[:doc_type].present?

    @all_loans = Loan.order(:borrower_name)
    @loans = @all_loans.where(status: "active") if @status == "pending"
    @pending_count = ClientUpload.pending.count

    # For filter dropdowns
    @uploaders = ClientUpload.where(status: @status).distinct.order(:client_name).pluck(:client_name, :client_email)
    @used_doc_types = ClientUpload.where(status: @status).distinct.order(:document_type).pluck(:document_type)
  end

  def show
    @loans = Loan.where(status: "active").order(:borrower_name)
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
