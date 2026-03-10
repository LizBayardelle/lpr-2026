class CreateLoanExtensions < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_extensions do |t|
      t.references :loan, null: false, foreign_key: true
      t.date :original_maturity_date, null: false
      t.date :new_maturity_date, null: false
      t.decimal :extension_fee, precision: 12, scale: 2, default: 0
      t.decimal :new_rate, precision: 5, scale: 3 # nil means rate unchanged
      t.text :notes

      t.timestamps
    end
  end
end
