class Admin::BlogsController < Admin::BaseController
  before_action :set_blog, only: [:edit, :update, :destroy, :publish, :unpublish]

  def index
    @blogs = Blog.recent.includes(:categories, :user)
  end

  def new
    @blog = current_user.blogs.build
    @categories = Category.sorted
  end

  def create
    @blog = current_user.blogs.build(blog_params)
    if @blog.save
      redirect_to admin_blogs_path, notice: "Blog created."
    else
      @categories = Category.sorted
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.sorted
  end

  def update
    if @blog.update(blog_params)
      redirect_to admin_blogs_path, notice: "Blog updated."
    else
      @categories = Category.sorted
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog.destroy
    redirect_to admin_blogs_path, notice: "Blog deleted."
  end

  def publish
    @blog.publish!
    redirect_to admin_blogs_path, notice: "\"#{@blog.title}\" is now published."
  end

  def unpublish
    @blog.unpublish!
    redirect_to admin_blogs_path, notice: "\"#{@blog.title}\" has been unpublished."
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :teaser, :body, :cover_image, category_ids: [])
  end
end
