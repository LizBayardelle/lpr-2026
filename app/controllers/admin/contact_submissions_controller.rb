class Admin::ContactSubmissionsController < Admin::BaseController
  before_action :set_submission, only: [:show, :mark_read, :archive]

  def index
    @status = params[:status].presence || "new"
    @submissions = ContactSubmission.recent
    @submissions = @submissions.where(status: @status) if ContactSubmission::STATUSES.include?(@status)
    @unread_count = ContactSubmission.unread.count
  end

  def show
    @submission.update!(status: "read") if @submission.status == "new"
  end

  def mark_read
    @submission.update!(status: "read")
    redirect_to admin_contact_submissions_path, notice: "Marked as read."
  end

  def archive
    @submission.update!(status: "archived")
    redirect_to admin_contact_submissions_path, notice: "Archived."
  end

  private

  def set_submission
    @submission = ContactSubmission.find(params[:id])
  end
end
