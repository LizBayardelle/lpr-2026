class AddClosingInterestToLoans < ActiveRecord::Migration[8.1]
  def change
    add_column :loans, :closing_interest, :decimal, precision: 12, scale: 2, default: 0, null: false
  end
end
