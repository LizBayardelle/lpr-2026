class AddOriginationFeeTypeAndFlatToLoans < ActiveRecord::Migration[8.1]
  def change
    add_column :loans, :origination_fee_type, :string, default: "percent", null: false
    add_column :loans, :origination_fee_flat, :decimal, precision: 12, scale: 2
  end
end
