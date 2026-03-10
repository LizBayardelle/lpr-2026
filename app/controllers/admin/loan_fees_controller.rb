class Admin::LoanFeesController < Admin::BaseController
  before_action :set_loan
  before_action :set_fee, only: [:edit, :update, :destroy, :mark_paid]

  def new
    @fee = @loan.loan_fees.build(fee_date: Date.current)
  end

  def create
    @fee = @loan.loan_fees.build(fee_params)
    if @fee.save
      redirect_to admin_loan_path(@loan), notice: "Fee added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @fee.update(fee_params)
      redirect_to admin_loan_path(@loan), notice: "Fee updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @fee.destroy
    redirect_to admin_loan_path(@loan), notice: "Fee deleted."
  end

  def mark_paid
    @fee.mark_paid!
    redirect_to admin_loan_path(@loan), notice: "Fee marked as paid."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_fee
    @fee = @loan.loan_fees.find(params[:id])
  end

  def fee_params
    params.require(:loan_fee).permit(:fee_type, :amount, :fee_date, :description, :paid)
  end
end
