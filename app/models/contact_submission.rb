class ContactSubmission < ApplicationRecord
  STATUSES = %w[new read replied archived].freeze

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :unread, -> { where(status: "new") }
  scope :recent, -> { order(created_at: :desc) }
end
