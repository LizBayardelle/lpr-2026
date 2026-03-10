class Admin::PaymentsController < Admin::BaseController
  before_action :set_loan
  before_action :set_payment, only: [:edit, :update, :destroy]

  def new
    @payment = @loan.payments.build(payment_date: Date.current)
  end

  def create
    @payment = @loan.payments.build(payment_params)
    if @payment.save
      redirect_to admin_loan_path(@loan), notice: "Payment of #{helpers.number_to_currency(@payment.amount)} recorded."
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

  def payment_params
    params.require(:payment).permit(
      :payment_date, :amount, :principal_amount, :interest_amount,
      :late_fee_amount, :extra_amount, :payment_method, :reference_number, :notes
    )
  end
end
