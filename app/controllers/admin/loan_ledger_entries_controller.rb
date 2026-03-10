class Admin::LoanLedgerEntriesController < Admin::BaseController
  before_action :set_loan
  before_action :set_entry, only: [:reverse]

  def create
    service = LoanLedger::PostingService.new(@loan, posted_by: current_user)
    service.post!({
      entry_type: "adjustment",
      effective_date: params[:effective_date].to_date,
      amount: params[:amount].to_d,
      description: params[:description]
    })
    redirect_to admin_loan_path(@loan, tab: "ledger"), notice: "Adjustment posted."
  rescue => e
    redirect_to admin_loan_path(@loan, tab: "ledger"), alert: "Could not post adjustment: #{e.message}"
  end

  def reverse
    service = LoanLedger::PostingService.new(@loan, posted_by: current_user)
    service.reverse!(@entry, reason: params[:reason].presence || "Admin reversal")
    redirect_to admin_loan_path(@loan, tab: "ledger"), notice: "Entry reversed."
  rescue => e
    redirect_to admin_loan_path(@loan, tab: "ledger"), alert: "Could not reverse entry: #{e.message}"
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_entry
    @entry = @loan.loan_ledger_entries.find(params[:id])
  end
end
