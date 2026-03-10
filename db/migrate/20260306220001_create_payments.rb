class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :loan, null: false, foreign_key: true
      t.date :payment_date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :principal_amount, precision: 12, scale: 2, default: 0
      t.decimal :interest_amount, precision: 12, scale: 2, default: 0
      t.decimal :late_fee_amount, precision: 12, scale: 2, default: 0
      t.decimal :extra_amount, precision: 12, scale: 2, default: 0 # escrow, fees, etc.
      t.string :payment_method # check, wire, ach, cash
      t.string :reference_number
      t.text :notes

      t.timestamps
    end

    add_index :payments, :payment_date
  end
end
