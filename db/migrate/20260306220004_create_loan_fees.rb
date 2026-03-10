class CreateLoanFees < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_fees do |t|
      t.references :loan, null: false, foreign_key: true
      t.string :fee_type, null: false # extension, modification, inspection, legal, other
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :fee_date, null: false
      t.string :description
      t.boolean :paid, default: false

      t.timestamps
    end
  end
end
