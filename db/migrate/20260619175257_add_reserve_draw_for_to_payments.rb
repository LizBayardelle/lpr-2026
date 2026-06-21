class AddReserveDrawForToPayments < ActiveRecord::Migration[8.1]
  def change
    # Links an auto-generated reserve-draw payment back to the cash payment it
    # compensates, so edits/deletes of the cash payment keep the reserve correct.
    add_reference :payments, :reserve_draw_for,
      foreign_key: { to_table: :payments }, null: true, index: true
  end
end
