class AddNameToLoanReserves < ActiveRecord::Migration[8.1]
  def change
    add_column :loan_reserves, :name, :string
  end
end
