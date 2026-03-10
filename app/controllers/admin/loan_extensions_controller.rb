class Admin::LoanExtensionsController < Admin::BaseController
  before_action :set_loan
  before_action :set_extension, only: [:destroy]

  def new
    @extension = @loan.loan_extensions.build(
      original_maturity_date: @loan.effective_maturity_date
    )
  end

  def create
    @extension = @loan.loan_extensions.build(extension_params)
    if @extension.save
      redirect_to admin_loan_path(@loan), notice: "Loan extended to #{@extension.new_maturity_date.strftime('%B %d, %Y')}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @extension.destroy
    redirect_to admin_loan_path(@loan), notice: "Extension removed."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_extension
    @extension = @loan.loan_extensions.find(params[:id])
  end

  def extension_params
    params.require(:loan_extension).permit(:original_maturity_date, :new_maturity_date, :extension_fee, :new_rate, :notes)
  end
end
