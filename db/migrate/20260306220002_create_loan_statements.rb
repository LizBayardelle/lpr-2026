class CreateLoanStatements < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_statements do |t|
      t.references :loan, null: false, foreign_key: true
      t.date :statement_date, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false

      t.decimal :beginning_balance, precision: 12, scale: 2, null: false
      t.decimal :ending_balance, precision: 12, scale: 2, null: false
      t.decimal :interest_due, precision: 12, scale: 2, null: false
      t.decimal :principal_due, precision: 12, scale: 2, default: 0
      t.decimal :total_due, precision: 12, scale: 2, null: false
      t.decimal :payments_received, precision: 12, scale: 2, default: 0
      t.decimal :late_fee, precision: 12, scale: 2, default: 0
      t.decimal :past_due_amount, precision: 12, scale: 2, default: 0

      t.text :notes

      t.timestamps
    end

    add_index :loan_statements, [:loan_id, :statement_date], unique: true
    add_index :loan_statements, :statement_date
  end
end
