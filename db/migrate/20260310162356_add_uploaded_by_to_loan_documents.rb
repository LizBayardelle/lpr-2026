class AddUploadedByToLoanDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :loan_documents, :uploaded_by_user, null: true, foreign_key: { to_table: :users }
    add_column :loan_documents, :uploaded_by_name, :string
  end
end
