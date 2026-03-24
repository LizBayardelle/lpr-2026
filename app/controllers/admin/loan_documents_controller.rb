class Admin::LoanDocumentsController < Admin::BaseController
  before_action :set_loan
  before_action :set_document, only: [:destroy]

  def create
    @document = @loan.loan_documents.build(document_params)
    @document.uploaded_by_user = current_user
    if @document.save
      # Mirror to client_uploads so it appears in the Document Portal
      upload = ClientUpload.new(
        client_name: current_user.display_name,
        client_email: current_user.email,
        document_type: @document.document_type,
        name: @document.name,
        description: @document.description,
        loan: @loan,
        status: "assigned",
        assigned_by_user: current_user,
        assigned_at: Time.current
      )
      upload.file.attach(@document.file.blob)
      upload.save!

      redirect_to admin_loan_path(@loan, tab: "documents"), notice: "Document uploaded."
    else
      redirect_to admin_loan_path(@loan, tab: "documents"), alert: "Could not upload document."
    end
  end

  def destroy
    @document.destroy
    redirect_to admin_loan_path(@loan), notice: "Document deleted."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_document
    @document = @loan.loan_documents.find(params[:id])
  end

  def document_params
    params.require(:loan_document).permit(:document_type, :name, :description, :file)
  end
end
