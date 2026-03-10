class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans do |t|
      # Borrower info
      t.string :borrower_name, null: false
      t.string :borrower_email
      t.string :borrower_phone
      t.text :borrower_address

      # Property / collateral
      t.string :property_address, null: false

      # Loan terms
      t.decimal :loan_amount, precision: 12, scale: 2, null: false
      t.decimal :interest_rate, precision: 5, scale: 3, null: false # annual %
      t.integer :loan_term_months, null: false
      t.decimal :origination_fee_percent, precision: 5, scale: 3, default: 0
      t.string :payment_type, default: "interest_only" # interest_only, fully_amortizing
      t.string :interest_calc_method, default: "30_360" # 30_360, actual_360, actual_365

      # Dates
      t.date :origination_date, null: false
      t.date :maturity_date, null: false
      t.date :first_payment_date

      # Default / late terms
      t.decimal :default_interest_rate, precision: 5, scale: 3
      t.decimal :late_fee_percent, precision: 5, scale: 3, default: 5.0
      t.integer :grace_period_days, default: 10

      # Status
      t.string :status, default: "active" # active, paid_off, default, foreclosure, extended

      t.text :notes

      t.timestamps
    end

    add_index :loans, :status
    add_index :loans, :borrower_name
    add_index :loans, :maturity_date
  end
end
