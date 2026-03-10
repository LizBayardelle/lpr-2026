class CreateLoanLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_ledger_entries do |t|
      t.references :loan, null: false, foreign_key: true
      t.string :entry_type, null: false
      t.date :effective_date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :running_balance, precision: 12, scale: 2, null: false
      t.string :description
      t.string :source_type
      t.bigint :source_id
      t.references :posted_by, foreign_key: { to_table: :users }, null: true
      t.bigint :reversed_by_id
      t.bigint :reversal_of_id
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :loan_ledger_entries, [:loan_id, :effective_date, :id]
    add_index :loan_ledger_entries, [:source_type, :source_id]
    add_index :loan_ledger_entries, :reversal_of_id
  end
end
