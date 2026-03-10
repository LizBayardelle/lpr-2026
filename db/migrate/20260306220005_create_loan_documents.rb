class CreateLoanDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_documents do |t|
      t.references :loan, null: false, foreign_key: true
      t.string :document_type, null: false # promissory_note, deed_of_trust, insurance, appraisal, title, other
      t.string :description

      t.timestamps
    end
  end
end
