class UploadsController < ApplicationController
  def new
    @upload = ClientUpload.new
  end

  def create
    @upload = ClientUpload.new(upload_params)
    if user_signed_in?
      @upload.client_name = current_user.display_name
      @upload.client_email = current_user.email
      @upload.client_phone = current_user.phone_number if @upload.client_phone.blank?
    end
    if @upload.save
      redirect_to upload_success_path, notice: "Your document has been uploaded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
  end

  private

  def upload_params
    params.require(:client_upload).permit(:client_name, :client_email, :client_phone, :document_type, :name, :description, :file)
  end
end
