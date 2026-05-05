class Admin::LoanReservesController < Admin::BaseController
  before_action :set_loan
  before_action :set_reserve, only: [:update, :draw, :release, :forfeit, :destroy]

  def create
    @reserve = @loan.loan_reserves.build(reserve_params)
    if @reserve.save
      redirect_to admin_loan_path(@loan, tab: "reserves"), notice: "#{@reserve.display_type} reserve of #{helpers.number_to_currency(@reserve.amount)} established."
    else
      redirect_to admin_loan_path(@loan, tab: "reserves"), alert: "Could not create reserve: #{@reserve.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @reserve.update(reserve_params)
      redirect_to admin_loan_path(@loan, tab: "reserves"), notice: "Reserve updated."
    else
      redirect_to admin_loan_path(@loan, tab: "reserves"), alert: "Could not update reserve: #{@reserve.errors.full_messages.join(', ')}"
    end
  end

  def draw
    amount = params[:amount].to_d
    if amount <= 0
      redirect_to admin_loan_path(@loan, tab: "reserves"), alert: "Draw amount must be greater than zero."
      return
    end

    if amount > @reserve.remaining_balance
      redirect_to admin_loan_path(@loan, tab: "reserves"), alert: "Draw amount exceeds reserve balance of #{helpers.number_to_currency(@reserve.remaining_balance)}."
      return
    end

    @reserve.draw!(
      amount: amount,
      payment_date: params[:payment_date].present? ? params[:payment_date].to_date : Date.current,
      notes: params[:notes].presence || "Reserve draw - #{@reserve.display_type}"
    )

    redirect_to admin_loan_path(@loan, tab: "reserves"), notice: "Drew #{helpers.number_to_currency(amount)} from reserve. Remaining: #{helpers.number_to_currency(@reserve.remaining_balance)}."
  rescue => e
    redirect_to admin_loan_path(@loan, tab: "reserves"), alert: "Could not draw from reserve: #{e.message}"
  end

  def release
    @reserve.release!
    redirect_to admin_loan_path(@loan, tab: "reserves"), notice: "Reserve released. #{helpers.number_to_currency(@reserve.remaining_balance)} returned to borrower."
  end

  def forfeit
    @reserve.forfeit!
    redirect_to admin_loan_path(@loan, tab: "reserves"), notice: "Reserve forfeited. #{helpers.number_to_currency(@reserve.remaining_balance)} retained by lender."
  end

  def destroy
    @reserve.destroy
    redirect_to admin_loan_path(@loan, tab: "reserves"), notice: "Reserve removed."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_reserve
    @reserve = @loan.loan_reserves.find(params[:id])
  end

  def reserve_params
    params.require(:loan_reserve).permit(:name, :amount, :reserve_type, :established_date, :notes, :source_type, :source_id)
  end
end
