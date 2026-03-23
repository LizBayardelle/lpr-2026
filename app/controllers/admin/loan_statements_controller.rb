class Admin::LoanStatementsController < Admin::BaseController
  before_action :set_loan
  before_action :set_statement, only: [:show, :destroy, :send_to_client]

  def show
    respond_to do |format|
      format.html do
        @period_payments = @loan.payments.for_period(@statement.period_start, @statement.period_end).order(:payment_date)
        @period_draws = @loan.loan_draws.funded.where(draw_date: @statement.period_start..@statement.period_end).order(:draw_date)
        @period_fees = @loan.loan_fees.where(fee_date: @statement.period_start..@statement.period_end).order(:fee_date)
        @statement_sends = @statement.statement_sends.includes(:sent_by).order(created_at: :desc)
        borrower_emails = @loan.borrowers.map(&:email).reject(&:blank?)
        @default_recipient_email = borrower_emails.first.presence || @loan.borrower_email
      end
      format.pdf do
        pdf_data = StatementPdf.new(@statement).render
        filename = "statement-#{@loan.borrower_name.parameterize}-#{@statement.period_end.strftime('%Y-%m')}.pdf"
        send_data pdf_data, filename: filename, type: "application/pdf", disposition: "inline"
      end
    end
  end

  def send_to_client
    if @statement.stale?
      redirect_to admin_loan_loan_statement_path(@loan, @statement), alert: "This statement is stale. Please regenerate it before sending."
      return
    end

    # Ensure PDF is attached
    unless @statement.pdf.attached?
      pdf_data = StatementPdf.new(@statement).render
      @statement.pdf.attach(
        io: StringIO.new(pdf_data),
        filename: "statement-#{@loan.borrower_name.parameterize}-#{@statement.period_end.strftime('%Y-%m')}.pdf",
        content_type: "application/pdf"
      )
    end

    statement_send = @statement.statement_sends.create!(
      sent_by: current_user,
      sent_to: params[:sent_to],
      cc_to: params[:cc_to]
    )

    StatementMailer.statement_to_borrower(statement_send).deliver_later
    redirect_to admin_loan_loan_statement_path(@loan, @statement), notice: "Statement sent to #{statement_send.sent_to}."
  end

  def destroy
    @statement.destroy
    redirect_to admin_loan_path(@loan), notice: "Statement deleted."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_statement
    @statement = @loan.loan_statements.find(params[:id])
  end
end
