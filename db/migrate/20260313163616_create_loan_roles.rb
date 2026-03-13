class CreateLoanRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :loan, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :loan_roles, [:user_id, :loan_id, :role], unique: true
  end
end
