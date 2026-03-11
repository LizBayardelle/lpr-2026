class ClientUpload < ApplicationRecord
  belongs_to :loan, optional: true
  belongs_to :assigned_by_user, class_name: "User", optional: true
  has_one_attached :file

  STATUSES = %w[pending assigned rejected].freeze

  validates :client_name, presence: true
  validates :client_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :document_type, presence: true, inclusion: { in: LoanDocument::DOCUMENT_TYPES.keys }
  validates :status, inclusion: { in: STATUSES }
  validate :file_attached

  scope :pending, -> { where(status: "pending") }
  scope :assigned, -> { where(status: "assigned") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def assigned?
    status == "assigned"
  end

  def rejected?
    status == "rejected"
  end

  def document_type_label
    LoanDocument::DOCUMENT_TYPES[document_type] || document_type
  end

  def assign_to_loan!(loan, user)
    transaction do
      doc = loan.loan_documents.build(
        document_type: document_type,
        name: name.presence || document_type_label,
        description: description,
        uploaded_by_name: client_name
      )
      doc.file.attach(file.blob)
      doc.save!

      update!(
        loan: loan,
        status: "assigned",
        assigned_by_user: user,
        assigned_at: Time.current
      )
    end
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
