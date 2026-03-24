class LoanMailer < ApplicationMailer
  def welcome_email(welcome_send)
    @welcome_send = welcome_send
    @loan = welcome_send.loan

    attachments["Payment-Options.pdf"] = {
      mime_type: "application/pdf",
      content: Net::HTTP.get(URI("https://linchpinrealty.s3.us-west-1.amazonaws.com/documents/Payment+Options.pdf"))
    }

    mail(
      to: @welcome_send.sent_to,
      cc: @welcome_send.cc_to.presence,
      subject: "Welcome to Linchpin Realty — Your Loan Details & Payment Options"
    )
  end
end
