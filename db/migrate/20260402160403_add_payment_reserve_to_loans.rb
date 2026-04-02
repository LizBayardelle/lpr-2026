class AddPaymentReserveToLoans < ActiveRecord::Migration[8.1]
  def change
    add_reference :loans, :payment_reserve, foreign_key: { to_table: :loan_reserves }, null: true
  end
end
