class AddPertainsToMonthToLedgerAndSources < ActiveRecord::Migration[8.1]
  def up
    add_column :loan_ledger_entries, :pertains_to_month, :date
    add_column :payments, :pertains_to_month, :date
    add_column :loan_draws, :pertains_to_month, :date
    add_column :loan_fees, :pertains_to_month, :date

    add_index :loan_ledger_entries, [:loan_id, :pertains_to_month]
    add_index :payments, [:loan_id, :pertains_to_month]
    add_index :loan_draws, [:loan_id, :pertains_to_month]
    add_index :loan_fees, [:loan_id, :pertains_to_month]

    # Backfill existing rows: an item pertains to the month of its own date.
    execute <<~SQL
      UPDATE loan_ledger_entries SET pertains_to_month = date_trunc('month', effective_date)::date WHERE pertains_to_month IS NULL;
      UPDATE payments            SET pertains_to_month = date_trunc('month', payment_date)::date   WHERE pertains_to_month IS NULL;
      UPDATE loan_draws          SET pertains_to_month = date_trunc('month', draw_date)::date      WHERE pertains_to_month IS NULL;
      UPDATE loan_fees           SET pertains_to_month = date_trunc('month', fee_date)::date       WHERE pertains_to_month IS NULL;
    SQL
  end

  def down
    remove_column :loan_ledger_entries, :pertains_to_month
    remove_column :payments, :pertains_to_month
    remove_column :loan_draws, :pertains_to_month
    remove_column :loan_fees, :pertains_to_month
  end
end
