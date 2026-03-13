class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :blogs, dependent: :destroy
  has_many :loan_roles, dependent: :destroy
  has_many :loans, through: :loan_roles

  def display_name
    [first_name, last_name].map(&:presence).compact.join(" ").presence || "Linchpin Realty Staff"
  end

  def invite_pending?
    reset_password_token.present?
  end
end
