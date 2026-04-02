class AddMonthlyCashPaymentToLoans < ActiveRecord::Migration[8.1]
  def change
    add_column :loans, :monthly_cash_payment, :decimal, precision: 12, scale: 2
  end
end
