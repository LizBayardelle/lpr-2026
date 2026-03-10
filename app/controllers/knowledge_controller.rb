class KnowledgeController < ApplicationController
  def index
    @blogs = Blog.published.recent.includes(:categories, :user, cover_image_attachment: :blob)
    @blogs = @blogs.by_category(params[:category]) if params[:category].present?
    @categories = Category.sorted
  end

  def show
    @blog = Blog.published.find(params[:id])
    @related_blogs = @blog.related(limit: 3)
  end
end
