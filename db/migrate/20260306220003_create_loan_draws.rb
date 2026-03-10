class CreateLoanDraws < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_draws do |t|
      t.references :loan, null: false, foreign_key: true
      t.date :draw_date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :description
      t.text :inspection_notes
      t.string :status, default: "pending" # pending, approved, funded, rejected

      t.timestamps
    end
  end
end
