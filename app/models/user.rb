class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :blogs, dependent: :destroy

  def display_name
    [first_name, last_name].map(&:presence).compact.join(" ").presence || "Linchpin Realty Staff"
  end
end
