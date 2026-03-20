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
      create_reserve_if_requested(@extension)
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

  def create_reserve_if_requested(extension)
    return unless params[:reserve_amount].present? && params[:reserve_amount].to_d > 0

    @loan.loan_reserves.create!(
      amount: params[:reserve_amount].to_d,
      reserve_type: params[:reserve_type].presence || "interest",
      established_date: Date.current,
      source: extension,
      notes: params[:reserve_notes]
    )
  end

  def extension_params
    params.require(:loan_extension).permit(:original_maturity_date, :new_maturity_date, :extension_fee, :new_rate, :notes)
  end
end
