class Blog < ApplicationRecord
  belongs_to :user
  has_many :category_blogs, dependent: :destroy
  has_many :categories, through: :category_blogs

  has_one_attached :cover_image

  validates :title, presence: true
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :recent, -> { order(published_at: :desc, created_at: :desc) }
  scope :by_category, ->(category) { joins(:categories).where(categories: { slug: category }) }

  def publish!
    update(published: true, published_at: published_at || Time.current)
  end

  def unpublish!
    update(published: false)
  end

  def author_name
    user&.godpowers? ? "Linchpin Team" : (user&.display_name || "Linchpin Team")
  end

  def related(limit: 3)
    return Blog.published.recent.where.not(id: id).limit(limit) if category_ids.empty?

    Blog.published
        .joins(:category_blogs)
        .where(category_blogs: { category_id: category_ids })
        .where.not(id: id)
        .distinct
        .order(published_at: :desc)
        .limit(limit)
  end
end
