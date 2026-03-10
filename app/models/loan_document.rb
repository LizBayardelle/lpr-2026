class LoanDocument < ApplicationRecord
  belongs_to :loan
  belongs_to :uploaded_by_user, class_name: "User", optional: true
  has_one_attached :file

  # Returns a display name for whoever uploaded the document
  def uploaded_by
    uploaded_by_user&.display_name || uploaded_by_name.presence || "Unknown"
  end

  DOCUMENT_TYPES = {
    # Loan docs
    "promissory_note" => "Promissory Note",
    "deed_of_trust" => "Deed of Trust",
    "loan_agreement" => "Loan Agreement",
    "loan_estimate" => "Loan Estimate",
    "closing_disclosure" => "Closing Disclosure",
    "settlement_statement" => "Settlement Statement (HUD-1)",
    # Property
    "appraisal" => "Appraisal",
    "title" => "Title Report",
    "title_insurance" => "Title Insurance",
    "property_insurance" => "Property Insurance",
    "inspection" => "Inspection Report",
    "survey" => "Survey",
    "purchase_agreement" => "Purchase Agreement",
    "scope_of_work" => "Scope of Work",
    "draw_request" => "Draw Request",
    # Borrower - income & employment
    "w2" => "W-2",
    "tax_return" => "Tax Return",
    "pay_stub" => "Pay Stub",
    "profit_loss" => "Profit & Loss Statement",
    "employment_verification" => "Employment Verification",
    "1099" => "1099",
    # Borrower - assets & financials
    "bank_statement" => "Bank Statement",
    "financial_statement" => "Financial Statement",
    "credit_report" => "Credit Report",
    "asset_verification" => "Asset Verification",
    # Borrower - identity & entity
    "photo_id" => "Photo ID",
    "social_security" => "Social Security Card",
    "entity_docs" => "Entity Documents (LLC/Corp)",
    "operating_agreement" => "Operating Agreement",
    "articles_of_incorporation" => "Articles of Incorporation",
    "certificate_of_good_standing" => "Certificate of Good Standing",
    # Compliance & legal
    "authorization" => "Borrower Authorization",
    "disclosure" => "Disclosure",
    "legal" => "Legal Document",
    "lien_release" => "Lien Release",
    "subordination_agreement" => "Subordination Agreement",
    "guarantee" => "Personal Guarantee",
    # Correspondence
    "correspondence" => "Correspondence",
    "notice" => "Notice",
    # Other
    "other" => "Other"
  }.freeze

  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES.keys }
  validate :file_attached

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
