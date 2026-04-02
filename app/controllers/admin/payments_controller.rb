class Admin::PaymentsController < Admin::BaseController
  before_action :set_loan
  before_action :set_payment, only: [:edit, :update, :destroy]

  def new
    @payment = @loan.payments.build(payment_date: Date.current)
  end

  def create
    @payment = @loan.payments.build(payment_params)
    if @payment.save
      reserve_draw = auto_draw_from_reserve(@payment)
      notice = "Payment of #{helpers.number_to_currency(@payment.amount)} recorded."
      if reserve_draw
        notice += " #{helpers.number_to_currency(reserve_draw.amount)} drawn from interest reserve."
      end
      redirect_to admin_loan_path(@loan), notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @payment.update(payment_params)
      redirect_to admin_loan_path(@loan, tab: "payments"), notice: "Payment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @payment.destroy
    redirect_to admin_loan_path(@loan, tab: "payments"), notice: "Payment deleted."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_payment
    @payment = @loan.payments.find(params[:id])
  end

  # When a cash payment is recorded on a split-payment loan, auto-draw
  # the remaining interest from the interest reserve.
  def auto_draw_from_reserve(payment)
    return unless @loan.split_payment?
    return if payment.loan_reserve_id.present? # already a reserve draw
    reserve = @loan.auto_draw_reserve
    return unless reserve

    draw_amount = @loan.reserve_payment_amount
    return if draw_amount <= 0
    return if draw_amount > reserve.remaining_balance

    reserve.draw!(
      amount: draw_amount,
      payment_date: payment.payment_date,
      notes: "Auto-draw: reserve portion of #{payment.payment_date.strftime('%b %Y')} payment"
    )
  end

  def payment_params
    params.require(:payment).permit(
      :payment_date, :amount, :principal_amount, :interest_amount,
      :late_fee_amount, :extra_amount, :payment_method, :reference_number, :notes
    )
  end
end
