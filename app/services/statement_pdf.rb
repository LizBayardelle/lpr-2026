class StatementPdf
  include ActionView::Helpers::NumberHelper

  NAVY       = "031d55"
  STEEL      = "8a8f9a"
  CONCRETE   = "c4c7cc"
  SOOT       = "1a1a1a"
  MAROON     = "571a1a"
  SLATE_BLUE = "678097"
  LIGHT_GRAY = "f4f5f6"
  RULE_GRAY  = "e5e7eb"
  WHITE      = "ffffff"

  COMPANY_NAME  = "Linchpin Realty LLC"
  COMPANY_DRE   = "DRE #02018158"
  COMPANY_NMLS  = "NMLS #2643847"
  COMPANY_EMAIL = "anthony@linchpinrealty.com"

  FONT_DIR = Rails.root.join("app/assets/fonts")

  def initialize(statement)
    @statement = statement
    @loan = statement.loan
  end

  def render
    Prawn::Document.new(page_size: "LETTER", margin: [40, 48, 56, 48]) do |pdf|
      register_fonts(pdf)
      pdf.font "BarlowCondensed"
      pdf.default_leading 1

      header(pdf)
      borrower_and_period(pdf)
      cards_row(pdf)
      activity_ledger(pdf)
      next_payment(pdf)
      footer(pdf)
    end.render
  end

  private

  def register_fonts(pdf)
    pdf.font_families.update(
      "BarlowCondensed" => {
        normal:      FONT_DIR.join("BarlowCondensed-Regular.ttf").to_s,
        medium:      FONT_DIR.join("BarlowCondensed-Medium.ttf").to_s,
        semi_bold:   FONT_DIR.join("BarlowCondensed-SemiBold.ttf").to_s,
        bold:        FONT_DIR.join("BarlowCondensed-Bold.ttf").to_s,
        extra_bold:  FONT_DIR.join("BarlowCondensed-ExtraBold.ttf").to_s
      }
    )
  end

  # ────────────────────────────────────────────────────────────────
  # HEADER - Navy bar with company info
  # ────────────────────────────────────────────────────────────────
  def header(pdf)
    pdf.font("BarlowCondensed", style: :bold, size: 20) do
      pdf.fill_color NAVY
      pdf.text "ACCOUNT STATEMENT", character_spacing: 0.5
      pdf.fill_color SOOT
    end
    pdf.move_down 4
    pdf.font("BarlowCondensed", style: :normal, size: 8) do
      pdf.fill_color STEEL
      pdf.text "#{COMPANY_NAME}  \u00B7  #{COMPANY_DRE}  \u00B7  #{COMPANY_NMLS}"
      pdf.fill_color SOOT
    end
    pdf.move_down 6
    pdf.stroke_color NAVY
    pdf.line_width = 2
    pdf.stroke_horizontal_rule
    pdf.line_width = 0.5
    pdf.move_down 16
  end

  # ────────────────────────────────────────────────────────────────
  # BORROWER + STATEMENT PERIOD
  # ────────────────────────────────────────────────────────────────
  def borrower_and_period(pdf)
    left_w = pdf.bounds.width * 0.55
    right_w = pdf.bounds.width * 0.45
    top = pdf.cursor

    # Left: borrower
    pdf.bounding_box([0, top], width: left_w) do
      label_text(pdf, "BILL TO")
      pdf.move_down 4
      pdf.font("BarlowCondensed", style: :semi_bold, size: 11) do
        pdf.text @loan.borrower_name
      end
      if @loan.borrower_address.present?
        pdf.move_down 2
        pdf.font("BarlowCondensed", style: :normal, size: 9) do
          pdf.fill_color STEEL
          pdf.text @loan.borrower_address, leading: 2
          pdf.fill_color SOOT
        end
      end
      pdf.move_down 2
      pdf.font("BarlowCondensed", style: :normal, size: 9) do
        pdf.fill_color STEEL
        pdf.text @loan.property_address
        pdf.fill_color SOOT
      end
    end

    # Right: statement info
    pdf.bounding_box([left_w, top], width: right_w) do
      [
        ["STATEMENT PERIOD", "#{@statement.period_start.strftime('%b %-d, %Y')} - #{@statement.period_end.strftime('%b %-d, %Y')}"],
        ["STATEMENT DATE", @statement.statement_date.strftime("%b %-d, %Y")],
        ["GENERATED", @statement.created_at.strftime("%b %-d, %Y")]
      ].each do |lbl, val|
        label_text(pdf, lbl, align: :right)
        pdf.move_down 2
        pdf.font("BarlowCondensed", style: :semi_bold, size: 9) { pdf.text val, align: :right }
        pdf.move_down 8
      end
    end

    pdf.move_down 20
  end

  # ────────────────────────────────────────────────────────────────
  # 3-COLUMN CARDS ROW
  # ────────────────────────────────────────────────────────────────
  def cards_row(pdf)
    gap = 12
    col_w = (pdf.bounds.width - gap * 2) / 3.0
    # Fixed height — enough for the tallest card (Amount Due with late fee + children)
    card_h = 185
    top = pdf.cursor

    card_drawers = [
      method(:draw_loan_details),
      method(:draw_period_summary),
      method(:draw_amount_due)
    ]

    3.times do |i|
      x = i * (col_w + gap)

      # Card border
      pdf.stroke_color RULE_GRAY
      pdf.line_width = 0.75
      rounded_rect(pdf, x, top, col_w, card_h, 4)
      pdf.stroke

      # Card content
      pdf.bounding_box([x + 16, top - 16], width: col_w - 32, height: card_h - 32) do
        card_drawers[i].call(pdf, col_w)
      end
    end

    pdf.move_cursor_to top - card_h - 16
  end

  def draw_loan_details(pdf, col_w)
    card_heading(pdf, "Loan Details")
    calc_method = @loan.interest_calc_method.gsub("_", "/").gsub(/[a-z]+/) { |w| w.capitalize }

    kv_rows(pdf, col_w - 32, [
      ["Principal", number_to_currency(@loan.loan_amount)],
      ["Interest Rate", "#{@loan.effective_interest_rate}%"],
      ["Calculated", calc_method],
      ["Origination", @loan.origination_date.strftime("%b %-d, %Y")],
      ["Payment Type", @loan.payment_type.titleize]
    ])
  end

  def draw_period_summary(pdf, col_w)
    card_heading(pdf, "Period Summary")
    inner = col_w - 32

    rows = [["Beginning Balance", number_to_currency(@statement.beginning_balance)]]

    draws = @loan.loan_draws.funded.where(draw_date: @statement.period_start..@statement.period_end)
    rows << ["Draws Funded", "+ #{number_to_currency(draws.sum(:amount))}"] if draws.any?

    rows += [
      ["Interest Charged", number_to_currency(@statement.interest_due)],
      ["Interest Paid", "(#{number_to_currency(period_payments.sum(:interest_amount))})"],
      ["Principal Paid", "(#{number_to_currency(period_payments.sum(:principal_amount))})"]
    ]

    kv_rows(pdf, inner, rows)

    pdf.move_down 2
    pdf.stroke_color SOOT
    pdf.line_width = 1.25
    pdf.stroke_horizontal_line 0, inner
    pdf.line_width = 0.5
    pdf.move_down 6

    kv_row_bold(pdf, inner, "Ending Balance", number_to_currency(@statement.ending_balance))
  end

  def draw_amount_due(pdf, col_w)
    card_heading(pdf, "Amount Due")
    inner = col_w - 32

    # Total Due (normal weight)
    kv_rows(pdf, inner, [["Total Due", number_to_currency(@statement.total_due)]])

    # Children with corner arrows
    children = [["Interest", number_to_currency(@statement.interest_due)]]
    children << ["Principal", number_to_currency(@statement.principal_due)] if @statement.principal_due > 0

    children.each do |label, value|
      draw_corner_arrow(pdf, 6, pdf.cursor - 4, CONCRETE)
      pdf.font("BarlowCondensed", style: :normal, size: 9) do
        pdf.fill_color CONCRETE
        pdf.text_box label, at: [16, pdf.cursor], width: inner * 0.6 - 16
        pdf.text_box value, at: [inner * 0.6, pdf.cursor], width: inner * 0.4, align: :right
        pdf.fill_color SOOT
      end
      pdf.move_down 14
    end

    if @statement.late_fee > 0
      draw_corner_arrow(pdf, 6, pdf.cursor - 4, MAROON)
      pdf.font("BarlowCondensed", style: :normal, size: 9) do
        pdf.fill_color MAROON
        pdf.text_box "Late Fee", at: [16, pdf.cursor], width: inner * 0.6 - 16
        pdf.text_box number_to_currency(@statement.late_fee), at: [inner * 0.6, pdf.cursor], width: inner * 0.4, align: :right
        pdf.fill_color SOOT
      end
      pdf.move_down 14
    end

    # Payments Received
    kv_rows(pdf, inner, [["Payments Received", "(#{number_to_currency(@statement.payments_received)})"]])

    pdf.move_down 2
    pdf.stroke_color SOOT
    pdf.line_width = 1.25
    pdf.stroke_horizontal_line 0, inner
    pdf.line_width = 0.5
    pdf.move_down 6

    if @statement.past_due_amount > 0
      kv_row_bold(pdf, inner, "Past Due", number_to_currency(@statement.past_due_amount), color: MAROON)
    else
      kv_row_bold(pdf, inner, "Paid in Full", number_to_currency(0), color: SLATE_BLUE)
    end
  end

  # ────────────────────────────────────────────────────────────────
  # ACTIVITY LEDGER TABLE
  # ────────────────────────────────────────────────────────────────
  def activity_ledger(pdf)
    # Card wrapper
    section_top = pdf.cursor
    activity = build_activity

    table_data = [[
      { content: "DATE", font_style: :bold },
      { content: "ITEM", font_style: :bold },
      { content: "AMOUNT", font_style: :bold },
      { content: "BALANCE", font_style: :bold }
    ]]

    activity.each do |entry|
      amount_text = if entry[:amount].nil?
        "-"
      elsif entry[:amount] < 0
        "(#{number_to_currency(entry[:amount].abs)})"
      else
        number_to_currency(entry[:amount])
      end

      amount_color = entry[:amount].present? && entry[:amount] < 0 ? SLATE_BLUE : SOOT

      table_data << [
        entry[:date].strftime("%b %-d, %Y"),
        entry[:item],
        { content: amount_text, text_color: amount_color },
        number_to_currency(entry[:balance])
      ]
    end

    table_data << [
      { content: "Ending Balance", colspan: 2, font_style: :bold },
      "",
      { content: number_to_currency(@statement.ending_balance), font_style: :bold }
    ]

    col_widths = [90, pdf.bounds.width - 16 - 90 - 90 - 90, 90, 90]

    # Draw card border around table area
    # First measure table height
    dummy = Prawn::Document.new(page_size: "LETTER", margin: [40, 48, 56, 48])
    register_fonts(dummy)
    dummy.font "BarlowCondensed"
    tbl = dummy.make_table(table_data, width: pdf.bounds.width - 16, column_widths: col_widths,
      cell_style: { size: 8, font: "BarlowCondensed", padding: [6, 8], border_width: 0 })
    table_h = tbl.height

    card_h = table_h + 52  # heading + padding
    pdf.stroke_color RULE_GRAY
    pdf.line_width = 0.75
    rounded_rect(pdf, 0, section_top, pdf.bounds.width, card_h, 4)
    pdf.stroke

    # Heading inside card
    pdf.bounding_box([16, section_top - 14], width: pdf.bounds.width - 32) do
      card_heading(pdf, "Loan Activity")
    end

    # Table inside card
    pdf.bounding_box([8, section_top - 40], width: pdf.bounds.width - 16) do
      pdf.table(table_data, width: pdf.bounds.width, column_widths: col_widths,
        cell_style: { size: 8, font: "BarlowCondensed", padding: [6, 8], border_width: 0, text_color: SOOT }
      ) do |t|
        t.row(0).background_color = LIGHT_GRAY
        t.row(0).size = 7
        t.row(0).text_color = STEEL
        t.row(0).padding = [6, 8]

        t.columns(2..3).align = :right

        t.rows(1..-2).borders = [:bottom]
        t.rows(1..-2).border_color = LIGHT_GRAY
        t.rows(1..-2).border_width = 0.5

        t.row(-1).borders = [:top]
        t.row(-1).border_color = SOOT
        t.row(-1).border_width = 1.25
        t.row(-1).padding = [8, 8, 6, 8]
      end
    end

    pdf.move_cursor_to section_top - card_h - 16
  end

  # ────────────────────────────────────────────────────────────────
  # NEXT PAYMENT
  # ────────────────────────────────────────────────────────────────
  def next_payment(pdf)
    return unless @loan.status == "active"

    label_text(pdf, "NEXT PAYMENT DUE")
    pdf.move_down 4
    pdf.font("BarlowCondensed", style: :semi_bold, size: 12) do
      pdf.fill_color NAVY
      amount = number_to_currency(@loan.monthly_payment_amount)
      due = @loan.next_payment_date.strftime("%b %-d, %Y")
      pdf.text amount
      pdf.fill_color SOOT
    end
    pdf.move_down 2
    pdf.font("BarlowCondensed", style: :normal, size: 9) do
      pdf.fill_color STEEL
      pdf.text "by #{@loan.next_payment_date.strftime('%b %-d, %Y')}"
      pdf.fill_color SOOT
    end

    if @loan.late_fee_percent.present? && @loan.late_fee_percent > 0 && @loan.grace_period_days.present?
      pdf.move_down 6
      pdf.font("BarlowCondensed", style: :normal, size: 7.5) do
        pdf.fill_color STEEL
        pdf.text "A late fee of #{@loan.late_fee_percent}% will be charged if payment is not received within #{@loan.grace_period_days} days of the due date."
        pdf.fill_color SOOT
      end
    end

    pdf.move_down 12
  end

  # ────────────────────────────────────────────────────────────────
  # FOOTER (every page)
  # ────────────────────────────────────────────────────────────────
  def footer(pdf)
    pdf.repeat(:all) do
      pdf.canvas do
        pdf.bounding_box([48, 38], width: pdf.bounds.width - 96, height: 20) do
          pdf.stroke_color RULE_GRAY
          pdf.stroke_horizontal_rule
          pdf.move_down 6
          pdf.font("BarlowCondensed", style: :normal, size: 7) do
            pdf.fill_color STEEL
            pdf.text "#{COMPANY_NAME}  \u00B7  #{COMPANY_EMAIL}  \u00B7  #{COMPANY_DRE}  \u00B7  #{COMPANY_NMLS}", align: :center
            pdf.fill_color SOOT
          end
        end
      end
    end
  end

  # ────────────────────────────────────────────────────────────────
  # DRAWING HELPERS
  # ────────────────────────────────────────────────────────────────

  def rounded_rect(pdf, x, y, w, h, r)
    pdf.move_to  x + r, y
    pdf.line_to  x + w - r, y
    pdf.curve_to [x + w, y - r], bounds: [[x + w, y], [x + w, y - r]]
    pdf.line_to  x + w, y - h + r
    pdf.curve_to [x + w - r, y - h], bounds: [[x + w, y - h], [x + w - r, y - h]]
    pdf.line_to  x + r, y - h
    pdf.curve_to [x, y - h + r], bounds: [[x, y - h], [x, y - h + r]]
    pdf.line_to  x, y - r
    pdf.curve_to [x + r, y], bounds: [[x, y], [x + r, y]]
  end

  def draw_corner_arrow(pdf, x, y, color)
    pdf.save_graphics_state do
      pdf.stroke_color color
      pdf.line_width = 0.75
      pdf.stroke_line [x, y + 6], [x, y]
      pdf.stroke_line [x, y], [x + 5, y]
    end
  end

  def label_text(pdf, text, align: :left)
    pdf.font("BarlowCondensed", style: :semi_bold, size: 7) do
      pdf.fill_color STEEL
      pdf.text text, character_spacing: 1.5, align: align
      pdf.fill_color SOOT
    end
  end

  def card_heading(pdf, text)
    pdf.font("BarlowCondensed", style: :semi_bold, size: 12) do
      pdf.text text, character_spacing: 0.3
    end
    pdf.move_down 10
  end

  def kv_rows(pdf, width, rows)
    rows.each do |label, value|
      pdf.font("BarlowCondensed", style: :normal, size: 9) do
        pdf.fill_color STEEL
        pdf.text_box label, at: [0, pdf.cursor], width: width * 0.6
        pdf.fill_color SOOT
        pdf.text_box value, at: [width * 0.6, pdf.cursor], width: width * 0.4, align: :right
      end
      pdf.move_down 15
    end
  end

  def kv_row_bold(pdf, width, label, value, color: SOOT)
    pdf.font("BarlowCondensed", style: :semi_bold, size: 9) do
      pdf.fill_color color
      pdf.text_box label, at: [0, pdf.cursor], width: width * 0.6
      pdf.text_box value, at: [width * 0.6, pdf.cursor], width: width * 0.4, align: :right
      pdf.fill_color SOOT
    end
    pdf.move_down 15
  end

  # ────────────────────────────────────────────────────────────────
  # DATA
  # ────────────────────────────────────────────────────────────────

  def period_payments
    @period_payments ||= @loan.payments.for_period(@statement.period_start, @statement.period_end)
  end

  def build_activity
    activity = []
    running_balance = @statement.beginning_balance

    activity << { date: @statement.period_start, item: "Previous Balance", amount: nil, balance: running_balance }

    if @statement.interest_due > 0
      running_balance += @statement.interest_due
      activity << { date: @statement.period_start, item: "Interest Due", amount: @statement.interest_due, balance: running_balance }
    end

    if @statement.principal_due > 0
      activity << { date: @statement.period_start, item: "Principal Due", amount: @statement.principal_due, balance: running_balance }
    end

    period = @statement.period_start..@statement.period_end

    @loan.loan_draws.funded.where(draw_date: period).order(:draw_date).each do |draw|
      desc = draw.description.present? ? " - #{draw.description}" : ""
      running_balance += draw.amount
      activity << { date: draw.draw_date, item: "Draw Funded#{desc}", amount: draw.amount, balance: running_balance }
    end

    @loan.loan_fees.where(fee_date: period).order(:fee_date).each do |fee|
      desc = fee.description.present? ? " (#{fee.description})" : ""
      activity << { date: fee.fee_date, item: "Fee - #{fee.fee_type.titleize}#{desc}", amount: fee.amount, balance: running_balance }
    end

    if @statement.late_fee > 0
      activity << { date: @statement.period_end, item: "Late Fee", amount: @statement.late_fee, balance: running_balance }
    end

    period_payments.order(:payment_date).each do |payment|
      running_balance -= payment.principal_amount
      ref = payment.reference_number.present? ? " (#{payment.reference_number})" : ""
      activity << { date: payment.payment_date, item: "Payment Received#{ref}", amount: -payment.amount, balance: running_balance }
    end

    activity.sort_by.with_index { |a, i| [a[:date], i] }
  end
end
