class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :blogs, dependent: :destroy
  has_many :loan_roles, dependent: :destroy
  has_many :loans, through: :loan_roles

  after_commit :auto_associate_loans, on: :create

  def display_name
    [first_name, last_name].map(&:presence).compact.join(" ").presence || "Linchpin Realty Staff"
  end

  def invite_pending?
    reset_password_token.present?
  end

  # Auto-create borrower loan_roles for any loans where this user's email
  # matches the borrower_email field (and no role already exists).
  def auto_associate_loans
    return if email.blank?

    Loan.where(borrower_email: email).find_each do |loan|
      loan_roles.find_or_create_by(loan: loan, role: "borrower")
    end
  end
end
