class AddOriginationFeeHandlingToLoans < ActiveRecord::Migration[8.1]
  def change
    add_column :loans, :origination_fee_handling, :string, default: "net_funded", null: false
  end
end
