class StatementMailer < ApplicationMailer
  def statement_to_borrower(statement_send)
    @statement_send = statement_send
    @statement = statement_send.loan_statement
    @loan = @statement.loan

    if @statement.pdf.attached?
      attachments[pdf_filename] = {
        mime_type: "application/pdf",
        content: @statement.pdf.download
      }
    end

    mail(
      to: @statement_send.sent_to,
      cc: @statement_send.cc_to.presence,
      subject: "Your Loan Statement — #{@statement.period_end.strftime('%b %Y')}"
    )
  end

  private

  def pdf_filename
    "statement-#{@loan.borrower_name.parameterize}-#{@statement.period_end.strftime('%Y-%m')}.pdf"
  end
end
