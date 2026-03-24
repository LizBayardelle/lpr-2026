class WelcomeEmailSend < ApplicationRecord
  belongs_to :loan
  belongs_to :sent_by, class_name: "User"

  validates :sent_to, presence: true
end
