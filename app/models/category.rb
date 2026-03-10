class Category < ApplicationRecord
  has_many :category_blogs, dependent: :destroy
  has_many :blogs, through: :category_blogs

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :sorted, -> { order(:sort, :name) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
