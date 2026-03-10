class AddNameToLoanDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :loan_documents, :name, :string
  end
end
