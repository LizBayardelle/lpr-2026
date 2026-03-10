namespace :ledger do
  desc "Backfill ledger entries for all existing loans from payment/draw/fee history"
  task backfill: :environment do
    Loan.find_each do |loan|
      if loan.loan_ledger_entries.any?
        puts "Skipping loan ##{loan.id} (#{loan.borrower_name}) — already has ledger entries"
        next
      end

      puts "Backfilling loan ##{loan.id} (#{loan.borrower_name})..."
      service = LoanLedger::PostingService.new(loan)

      # 1. Disbursement
      service.post!({
        entry_type: "disbursement",
        effective_date: loan.origination_date,
        amount: loan.loan_amount,
        description: "Initial loan disbursement"
      })

      # 2. Draws (funded only, in date order)
      loan.loan_draws.funded.order(:draw_date).each do |draw|
        service.post!({
          entry_type: "draw",
          effective_date: draw.draw_date,
          amount: draw.amount,
          description: "Draw funded#{draw.description.present? ? ": #{draw.description}" : ""}",
          source: draw
        })
      end

      # 3. Interest accruals — backfill daily from origination to yesterday
      (loan.origination_date...Date.current).each do |date|
        # Get balance as of this date from the last balance-affecting entry
        last_entry = loan.loan_ledger_entries.order(id: :desc).first
        balance = last_entry&.running_balance || BigDecimal("0")
        next if balance <= 0

        daily = loan.daily_interest(balance)
        next if daily <= 0

        service.post!({
          entry_type: "interest_accrual",
          effective_date: date,
          amount: daily,
          description: "Daily interest accrual",
          metadata: { balance: balance.to_f, rate: loan.effective_interest_rate.to_f, calc_method: loan.interest_calc_method }
        })
      end

      # 4. Payments (in date order)
      loan.payments.order(:payment_date).each do |payment|
        entries = []
        if payment.interest_amount.to_d > 0
          entries << { entry_type: "payment_interest", effective_date: payment.payment_date,
                       amount: -payment.interest_amount, description: "Interest payment", source: payment }
        end
        if payment.principal_amount.to_d > 0
          entries << { entry_type: "payment_principal", effective_date: payment.payment_date,
                       amount: -payment.principal_amount, description: "Principal payment", source: payment }
        end
        if payment.late_fee_amount.to_d > 0
          entries << { entry_type: "payment_late_fee", effective_date: payment.payment_date,
                       amount: -payment.late_fee_amount, description: "Late fee payment", source: payment }
        end
        service.post!(entries) if entries.any?
      end

      # 5. Fees
      loan.loan_fees.order(:fee_date).each do |fee|
        service.post!({
          entry_type: "fee_assessed",
          effective_date: fee.fee_date,
          amount: fee.amount,
          description: "#{fee.fee_type.titleize} fee assessed",
          source: fee
        })
        if fee.paid?
          service.post!({
            entry_type: "fee_paid",
            effective_date: fee.updated_at.to_date,
            amount: -fee.amount,
            description: "#{fee.fee_type.titleize} fee paid",
            source: fee
          })
        end
      end

      # 6. Extension fees
      loan.loan_extensions.order(:created_at).each do |ext|
        next unless ext.extension_fee.to_d > 0
        service.post!({
          entry_type: "extension_fee",
          effective_date: ext.created_at.to_date,
          amount: ext.extension_fee,
          description: "Extension fee",
          source: ext
        })
      end

      final_balance = loan.loan_ledger_entries.order(id: :desc).first&.running_balance
      puts "  → #{loan.loan_ledger_entries.count} entries, final balance: #{final_balance}"
    end

    puts "Done!"
  end
end
