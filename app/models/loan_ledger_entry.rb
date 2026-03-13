class LoanLedgerEntry < ApplicationRecord
  belongs_to :loan
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :posted_by, class_name: "User", optional: true
  belongs_to :reversed_by_entry, class_name: "LoanLedgerEntry", foreign_key: :reversed_by_id, optional: true
  belongs_to :reversal_of_entry, class_name: "LoanLedgerEntry", foreign_key: :reversal_of_id, optional: true

  ENTRY_TYPES = %w[
    disbursement draw
    interest_accrual
    payment_principal payment_interest payment_late_fee
    fee_assessed fee_paid
    late_fee_assessed
    adjustment adjustment_principal
    extension_fee
  ].freeze

  # All entry types affect the total amount owed (running_balance)
  BALANCE_AFFECTING_TYPES = ENTRY_TYPES

  # Only these affect the principal balance (not plain "adjustment" which is for fee waivers etc.)
  PRINCIPAL_AFFECTING_TYPES = %w[disbursement draw payment_principal adjustment_principal].freeze

  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :effective_date, :amount, :running_balance, presence: true

  scope :chronological, -> { order(:effective_date, :id) }
  scope :reverse_chronological, -> { order(effective_date: :desc, id: :desc) }
  scope :balance_affecting, -> { where(entry_type: BALANCE_AFFECTING_TYPES) }
  scope :principal_affecting, -> { where(entry_type: PRINCIPAL_AFFECTING_TYPES) }
  scope :not_reversed, -> { where(reversed_by_id: nil) }
  scope :for_period, ->(start_date, end_date) { where(effective_date: start_date..end_date) }

  def reversed?
    reversed_by_id.present?
  end

  def reversal?
    reversal_of_id.present?
  end

  def balance_affecting?
    true
  end

  def principal_affecting?
    PRINCIPAL_AFFECTING_TYPES.include?(entry_type)
  end

  def human_type
    entry_type.titleize
  end
end
