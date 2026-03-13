class LoanRole < ApplicationRecord
  ROLES = %w[
    borrower coborrower guarantor vesting_entity
    broker processor underwriter closer servicer
    lender_investor title_officer escrow_officer
    attorney accountant internal_admin owner_manager
  ].freeze

  belongs_to :user
  belongs_to :loan

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: [:loan_id, :role], message: "already has this role on this loan" }

  def role_label
    role.titleize.gsub("_", " ")
  end
end
