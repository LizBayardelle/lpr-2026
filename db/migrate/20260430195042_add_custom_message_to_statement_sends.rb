class AddCustomMessageToStatementSends < ActiveRecord::Migration[8.1]
  def change
    add_column :statement_sends, :custom_message, :text
  end
end
