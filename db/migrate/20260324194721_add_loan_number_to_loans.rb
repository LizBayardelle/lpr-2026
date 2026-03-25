class AddLoanNumberToLoans < ActiveRecord::Migration[8.1]
  def change
    add_column :loans, :loan_number, :string
  end
end
