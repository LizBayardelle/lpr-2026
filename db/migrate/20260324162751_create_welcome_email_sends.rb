class CreateWelcomeEmailSends < ActiveRecord::Migration[8.1]
  def change
    create_table :welcome_email_sends do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :sent_by, null: false, foreign_key: { to_table: :users }
      t.string :sent_to, null: false
      t.string :cc_to

      t.timestamps
    end
  end
end
