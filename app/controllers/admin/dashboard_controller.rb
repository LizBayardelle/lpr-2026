class Admin::DashboardController < Admin::BaseController
  def index
    @recent_blogs = Blog.recent.limit(5).includes(:user, :categories)
    @published_count = Blog.published.count
    @draft_count = Blog.where(published: false).count
    @category_count = Category.count

    # Loan stats
    @active_loans_count = Loan.active.count
    @total_portfolio = Loan.active.sum(:loan_amount)
    @maturing_soon_count = Loan.maturing_soon(30).count

    # Client uploads
    @pending_uploads_count = ClientUpload.pending.count

    # Contact messages
    @unread_messages_count = ContactSubmission.unread.count
  end
end
