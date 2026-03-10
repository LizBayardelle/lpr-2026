class PagesController < ApplicationController
  def home
  end

  def styleguide
  end

  def loans
    @loan_blogs = Blog.published.recent.by_category("loans").includes(:categories, :user, cover_image_attachment: :blob).limit(6)
  end

  def lenders
    @lender_blogs = Blog.published.recent.by_category("lenders").includes(:categories, :user, cover_image_attachment: :blob).limit(6)
  end

  def invest
    @invest_blogs = Blog.published.recent.by_category("investing").includes(:categories, :user, cover_image_attachment: :blob).limit(6)
  end
end
