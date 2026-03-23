class StatementSend < ApplicationRecord
  belongs_to :loan_statement
  belongs_to :sent_by, class_name: "User"

  validates :sent_to, presence: true
end
