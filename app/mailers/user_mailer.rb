class UserMailer < ApplicationMailer
  def invite(user, invited_by)
    @user = user
    @invited_by = invited_by
    @token = user.send(:set_reset_password_token)
    @url = edit_user_password_url(reset_password_token: @token)

    mail(to: @user.email, subject: "You've been invited to Linchpin Realty")
  end

  def password_reset(user, raw_token)
    @user = user
    @url = edit_user_password_url(reset_password_token: raw_token)

    mail(to: @user.email, subject: "Reset your Linchpin Realty password")
  end
end
