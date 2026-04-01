class AddResponsiblePartyAndPropertyDetailsToLoans < ActiveRecord::Migration[8.1]
  def change
    # Responsible party (contact person) — distinct from legal borrower
    add_column :loans, :responsible_party_name, :string
    add_column :loans, :responsible_party_email, :string
    add_column :loans, :responsible_party_phone, :string
    add_column :loans, :responsible_party_address, :text

    # Property details
    add_column :loans, :property_type, :string
    add_column :loans, :property_subtype, :string
    add_column :loans, :property_valuation, :decimal, precision: 12, scale: 2
    add_column :loans, :property_taxes_last_paid_on, :date
    add_column :loans, :property_taxes_next_due_on, :date
    add_column :loans, :property_tax_notes, :text
  end
end
