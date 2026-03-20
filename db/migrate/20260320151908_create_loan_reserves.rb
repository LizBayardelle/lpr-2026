class CreateLoanReserves < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_reserves do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :reserve_type, null: false, default: "interest"
      t.string :status, null: false, default: "active"
      t.date :established_date, null: false
      t.references :source, polymorphic: true # Loan or LoanExtension
      t.text :notes

      t.timestamps
    end

    add_reference :payments, :loan_reserve, foreign_key: true, null: true
  end
end
