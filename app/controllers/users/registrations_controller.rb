class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_recaptcha, only: :create

  protected

  def after_update_path_for(_resource)
    dashboard_path
  end

  private

  def check_recaptcha
    return if verify_recaptcha(action: "signup", minimum_score: 0.5, secret_key: ENV["RECAPTCHA_SECRET_KEY"])

    self.resource = resource_class.new sign_up_params
    resource.validate
    set_minimum_password_length
    flash.now[:alert] = "Account creation failed. Please try again."
    respond_with_navigational(resource) { render :new }
  end
end
