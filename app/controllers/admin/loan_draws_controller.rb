class Admin::LoanDrawsController < Admin::BaseController
  before_action :set_loan
  before_action :set_draw, only: [:edit, :update, :destroy, :fund, :approve, :reject]

  def new
    @draw = @loan.loan_draws.build(draw_date: Date.current)
  end

  def create
    @draw = @loan.loan_draws.build(draw_params)
    if @draw.save
      redirect_to admin_loan_path(@loan, tab: "draws"), notice: "Draw request created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @draw.update(draw_params)
      redirect_to admin_loan_path(@loan, tab: "draws"), notice: "Draw updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @draw.destroy
    redirect_to admin_loan_path(@loan, tab: "draws"), notice: "Draw deleted."
  end

  def fund
    @draw.fund!
    redirect_to admin_loan_path(@loan, tab: "draws"), notice: "Draw funded."
  end

  def approve
    @draw.approve!
    redirect_to admin_loan_path(@loan, tab: "draws"), notice: "Draw approved."
  end

  def reject
    @draw.reject!
    redirect_to admin_loan_path(@loan, tab: "draws"), notice: "Draw rejected."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def set_draw
    @draw = @loan.loan_draws.find(params[:id])
  end

  def draw_params
    params.require(:loan_draw).permit(:draw_date, :amount, :description, :inspection_notes, :status)
  end
end
