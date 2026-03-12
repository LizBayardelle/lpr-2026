class ContactController < ApplicationController
  def show
  end

  def create
    unless verify_recaptcha(action: "contact", minimum_score: 0.5, secret_key: ENV["RECAPTCHA_SECRET_KEY"])
      @submission = ContactSubmission.new(contact_params)
      @errors = @submission.errors
      flash.now[:alert] = "reCAPTCHA verification failed. Please try again."
      return render :show, status: :unprocessable_entity
    end

    @submission = ContactSubmission.new(contact_params)
    if @submission.save
      redirect_to contact_path, notice: "Thanks for reaching out! We'll get back to you soon."
    else
      @errors = @submission.errors
      render :show, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact_submission).permit(:name, :email, :phone, :subject, :message)
  end
end
