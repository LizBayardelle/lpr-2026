class Admin::PaymentsController < Admin::BaseController
  before_action :set_loan
  before_action :set_payment, only: [:edit, :update, :destroy]
  before_action :block_auto_reserve_draw, only: [:edit, :update, :destroy]

  def new
    @payment = @loan.payments.build(payment_date: Date.current)
  end

  def create
    @payment = @loan.payments.build(payment_params)
    if @payment.save
      notice = "Payment of #{helpers.number_to_currency(@payment.amount)} recorded."
      if (reserve_draw = @payment.reserve_draw)
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

  # Auto reserve draws are managed through their parent cash payment, so editing
  # or deleting them directly is blocked — that's what keeps the reserve correct.
  def block_auto_reserve_draw
    return unless @payment.auto_reserve_draw?
    redirect_to admin_loan_path(@loan, tab: "payments"),
      alert: "That's an automatic reserve draw — edit or delete its cash payment instead and the reserve draw follows it automatically."
  end

  def payment_params
    params.require(:payment).permit(
      :payment_date, :amount, :principal_amount, :interest_amount,
      :late_fee_amount, :extra_amount, :payment_method, :reference_number, :notes,
      :pertains_to_month
    )
  end
end
