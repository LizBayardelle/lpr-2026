class UploadMailer < ApplicationMailer
  def upload_notification(client_upload)
    @upload = client_upload

    if @upload.file.attached?
      attachments[@upload.file.filename.to_s] = {
        mime_type: @upload.file.content_type,
        content: @upload.file.download
      }
    end

    mail(
      to: "anthony@linchpinrealty.com",
      subject: "New Document Upload from #{@upload.client_name}"
    )
  end
end
