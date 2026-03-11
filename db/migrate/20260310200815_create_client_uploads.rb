class CreateClientUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :client_uploads do |t|
      t.string :client_name, null: false
      t.string :client_email, null: false
      t.string :client_phone
      t.string :document_type, null: false
      t.string :name
      t.text :description
      t.string :status, null: false, default: "pending"
      t.references :loan, null: true, foreign_key: true
      t.bigint :assigned_by_user_id
      t.datetime :assigned_at

      t.timestamps
    end

    add_index :client_uploads, :status
    add_foreign_key :client_uploads, :users, column: :assigned_by_user_id
  end
end
