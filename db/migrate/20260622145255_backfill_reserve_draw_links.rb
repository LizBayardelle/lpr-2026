class BackfillReserveDrawLinks < ActiveRecord::Migration[8.1]
  # Link legacy auto-generated reserve draws (created before the parent-link
  # feature) back to the cash payment they compensate, so deleting/editing the
  # cash payment cascades to the reserve draw like newly-created ones do.
  def up
    say_with_time "Linking legacy auto reserve draws to parent cash payments" do
      linked = 0
      Payment.where.not(loan_reserve_id: nil)
             .where(reserve_draw_for_id: nil)
             .where("notes LIKE ?", "Auto-draw: reserve portion of%")
             .find_each do |draw|
        # Candidate parents: cash payments (no reserve, not themselves a draw) on
        # the same date that don't already have a reserve draw attached.
        candidates = Payment.where(loan_id: draw.loan_id, loan_reserve_id: nil,
                                   reserve_draw_for_id: nil, payment_date: draw.payment_date)
                            .where.not(id: Payment.where.not(reserve_draw_for_id: nil).select(:reserve_draw_for_id))

        # Only link when the pairing is unambiguous.
        if candidates.count == 1
          draw.update_columns(reserve_draw_for_id: candidates.first.id)
          linked += 1
        end
      end
      linked
    end
  end

  def down
    # Links are additive and safe to keep; nothing to reverse.
  end
end
