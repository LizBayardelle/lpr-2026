class RemoveUniqueIndexFromLoanStatements < ActiveRecord::Migration[8.1]
  def change
    remove_index :loan_statements, [:loan_id, :statement_date], unique: true
    add_index :loan_statements, [:loan_id, :statement_date]
  end
end
