class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :toggle_admin, :toggle_godpowers, :resend_invite, :send_reset]
  before_action :require_godpowers, only: [:toggle_admin, :toggle_godpowers]

  def index
    @users = User.order(:last_name, :first_name, :email)
    @users = @users.where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?

    case params[:filter]
    when "admin"
      @users = @users.where(admin: true)
    when "godpowers"
      @users = @users.where(godpowers: true)
    end
  end

  def show
    @loan_roles = @user.loan_roles.includes(:loan).order("loans.borrower_name")
    @available_loans = Loan.order(:borrower_name)
  end

  def new
    @user = User.new
    @available_loans = Loan.order(:borrower_name)
  end

  def create
    @user = User.new(user_params)

    if params[:invite_method] == "send_invite"
      @user.password = SecureRandom.hex(20)
    end

    if @user.save
      if params[:loan_ids].present? && params[:loan_role].present?
        Array(params[:loan_ids]).each do |loan_id|
          @user.loan_roles.create(loan_id: loan_id, role: params[:loan_role])
        end
      end

      if params[:invite_method] == "send_invite"
        UserMailer.invite(@user, current_user).deliver_later
        redirect_to admin_user_path(@user), notice: "User created and invitation sent to #{@user.email}."
      else
        redirect_to admin_user_path(@user), notice: "User created with temporary password."
      end
    else
      @available_loans = Loan.order(:borrower_name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @loan_roles = @user.loan_roles.includes(:loan).order("loans.borrower_name")
    @available_loans = Loan.order(:borrower_name)
  end

  def update
    if params[:user][:password].blank?
      params[:user].delete(:password)
    end

    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated."
    else
      @loan_roles = @user.loan_roles.includes(:loan).order("loans.borrower_name")
      @available_loans = Loan.order(:borrower_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_admin
    if @user == current_user
      redirect_to admin_user_path(@user), alert: "You cannot change your own admin status."
      return
    end

    @user.update!(admin: !@user.admin?)
    status = @user.admin? ? "granted" : "revoked"
    redirect_to admin_user_path(@user), notice: "Admin access #{status} for #{@user.display_name}."
  end

  def toggle_godpowers
    if @user == current_user
      redirect_to admin_user_path(@user), alert: "You cannot change your own godpowers status."
      return
    end

    @user.update!(godpowers: !@user.godpowers?)
    status = @user.godpowers? ? "granted" : "revoked"
    redirect_to admin_user_path(@user), notice: "Godpowers #{status} for #{@user.display_name}."
  end

  def resend_invite
    UserMailer.invite(@user, current_user).deliver_later
    redirect_to admin_user_path(@user), notice: "Invitation resent to #{@user.email}."
  end

  def send_reset
    raw_token = @user.send(:set_reset_password_token)
    UserMailer.password_reset(@user, raw_token).deliver_later
    redirect_to admin_user_path(@user), notice: "Password reset email sent to #{@user.email}."
  end

  # Loan role management (nested actions via form on show/edit)
  def add_loan_role
    @user = User.find(params[:id])
    loan_role = @user.loan_roles.build(loan_id: params[:loan_id], role: params[:role])

    if loan_role.save
      redirect_to admin_user_path(@user), notice: "#{loan_role.role_label} role added."
    else
      redirect_to admin_user_path(@user), alert: loan_role.errors.full_messages.join(", ")
    end
  end

  def remove_loan_role
    @user = User.find(params[:id])
    loan_role = @user.loan_roles.find(params[:loan_role_id])
    loan_role.destroy
    redirect_to admin_user_path(@user), notice: "Loan role removed."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def require_godpowers
    redirect_to admin_users_path, alert: "Not authorized." unless current_user.godpowers?
  end

  def user_params
    permitted = [:first_name, :last_name, :email, :phone_number, :notes, :password, :admin]
    permitted << :godpowers if current_user.godpowers?
    params.require(:user).permit(permitted)
  end
end
