class AddCustomMessageToWelcomeEmailSends < ActiveRecord::Migration[8.1]
  def change
    add_column :welcome_email_sends, :custom_message, :text
  end
end
