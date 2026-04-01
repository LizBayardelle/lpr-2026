class LoanMailer < ApplicationMailer
  def welcome_email(welcome_send, document_ids: [])
    @welcome_send = welcome_send
    @loan = welcome_send.loan
    @custom_message = welcome_send.custom_message

    attachments["Payment-Options.pdf"] = {
      mime_type: "application/pdf",
      content: Net::HTTP.get(URI("https://linchpinrealty.s3.us-west-1.amazonaws.com/documents/Payment+Options.pdf"))
    }

    @attached_documents = []
    if document_ids.any?
      @loan.loan_documents.where(id: document_ids).each do |doc|
        next unless doc.file.attached?

        attachments[doc.file.filename.to_s] = {
          mime_type: doc.file.content_type,
          content: doc.file.download
        }
        @attached_documents << (doc.name.presence || LoanDocument::DOCUMENT_TYPES[doc.document_type] || doc.document_type.titleize)
      end
    end

    mail(
      to: @welcome_send.sent_to,
      cc: @welcome_send.cc_to.presence,
      subject: "Welcome to Linchpin Realty — Your Loan Details & Payment Options"
    )
  end
end
