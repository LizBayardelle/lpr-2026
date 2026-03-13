class Loan < ApplicationRecord
  has_many :payments, dependent: :destroy
  has_many :loan_statements, dependent: :destroy
  has_many :loan_draws, dependent: :destroy
  has_many :loan_fees, dependent: :destroy
  has_many :loan_documents, dependent: :destroy
  has_many :loan_extensions, dependent: :destroy
  has_many :loan_ledger_entries, dependent: :destroy
  has_many :client_uploads
  has_many :loan_roles, dependent: :destroy
  has_many :users, through: :loan_roles

  after_create_commit :post_disbursement_to_ledger

  def users_with_role(role)
    users.merge(LoanRole.where(role: role))
  end

  def borrowers
    users_with_role("borrower")
  end

  def lender_investors
    users_with_role("lender_investor")
  end

  validates :borrower_name, presence: true
  validates :property_address, presence: true
  validates :loan_amount, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate, presence: true, numericality: { greater_than: 0, less_than: 100 }
  validates :loan_term_months, presence: true, numericality: { greater_than: 0 }
  validates :origination_fee_percent, numericality: { greater_than_or_equal_to: 0, less_than: 100 }, allow_nil: true
  validates :origination_fee_flat, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :default_interest_rate, numericality: { greater_than_or_equal_to: 0, less_than: 100 }, allow_nil: true
  validates :late_fee_percent, numericality: { greater_than_or_equal_to: 0, less_than: 100 }, allow_nil: true
  validates :origination_date, presence: true
  validates :maturity_date, presence: true
  validates :payment_type, inclusion: { in: %w[interest_only fully_amortizing] }
  validates :interest_calc_method, inclusion: { in: %w[30_360 actual_360 actual_365] }
  validates :status, inclusion: { in: %w[active paid_off default foreclosure extended] }
  validates :origination_fee_type, inclusion: { in: %w[percent flat] }
  validates :origination_fee_handling, inclusion: { in: %w[net_funded collected_separately] }

  scope :active, -> { where(status: "active") }
  scope :defaulted, -> { where(status: "default") }
  scope :by_maturity, -> { order(:maturity_date) }
  scope :maturing_soon, ->(days = 30) { active.where(maturity_date: ..days.days.from_now.to_date) }

  # Current amount owed — from the most recent entry in chronological order
  def current_balance
    loan_ledger_entries.order(effective_date: :desc, id: :desc).pick(:running_balance) || (funded_amount - total_principal_paid)
  end

  # Total amount actually funded (original + draws)
  def funded_amount
    loan_amount + loan_draws.where(status: "funded").sum(:amount)
  end

  # Total principal paid to date
  def total_principal_paid
    payments.sum(:principal_amount)
  end

  # Total interest paid to date
  def total_interest_paid
    payments.sum(:interest_amount)
  end

  # Total of all payments received
  def total_payments_received
    payments.sum(:amount)
  end

  # Monthly interest due based on current balance
  def monthly_interest_due(balance = nil)
    balance ||= current_balance
    case interest_calc_method
    when "30_360"
      (balance * interest_rate / 100 / 12).round(2)
    when "actual_360"
      (balance * interest_rate / 100 * 30 / 360).round(2)
    when "actual_365"
      (balance * interest_rate / 100 * 30 / 365).round(2)
    end
  end

  # Daily interest accrual
  def daily_interest(balance = nil)
    balance ||= current_balance
    case interest_calc_method
    when "30_360"
      (balance * interest_rate / 100 / 360).round(2)
    when "actual_360"
      (balance * interest_rate / 100 / 360).round(2)
    when "actual_365"
      (balance * interest_rate / 100 / 365).round(2)
    end
  end

  # Monthly payment amount (interest-only or amortized)
  def monthly_payment_amount
    if payment_type == "interest_only"
      monthly_interest_due
    else
      # Standard amortization formula
      r = interest_rate / 100 / 12
      n = loan_term_months
      bal = current_balance
      (bal * r * (1 + r)**n / ((1 + r)**n - 1)).round(2)
    end
  end

  # Calculate late fee for a given amount
  def calculate_late_fee(amount_past_due)
    (amount_past_due * (late_fee_percent || 0) / 100.0).round(2)
  end

  # Is the loan past maturity?
  def matured?
    maturity_date < Date.current
  end

  # Days until maturity (negative if past due)
  def days_to_maturity
    (maturity_date - Date.current).to_i
  end

  # Current effective interest rate (accounts for extensions with rate changes)
  def effective_interest_rate
    latest_extension = loan_extensions.order(:created_at).last
    latest_extension&.new_rate || interest_rate
  end

  # Current effective maturity date (accounts for extensions)
  def effective_maturity_date
    latest_extension = loan_extensions.order(:created_at).last
    latest_extension&.new_maturity_date || maturity_date
  end

  # Total fees assessed on the loan (excludes origination fee, which is a closing cost)
  def total_fees
    loan_fees.sum(:amount)
  end

  # Total interest accrued from ledger, or fall back to interest paid
  def total_interest_accrued
    accrued = loan_ledger_entries.not_reversed.where(entry_type: "interest_accrual").sum(:amount)
    accrued > 0 ? accrued : total_interest_paid
  end

  # Origination fee in dollars
  def origination_fee
    if origination_fee_type == "flat"
      origination_fee_flat.to_d
    else
      (loan_amount * (origination_fee_percent || 0) / 100.0).round(2)
    end
  end

  # Unpaid fees — all outstanding
  def unpaid_fees
    loan_fees.where(paid: false).sum(:amount)
  end

  # Unpaid fees for the current month only (for next payment box)
  def unpaid_fees_current_month
    loan_fees.where(paid: false)
             .where(fee_date: Date.current.beginning_of_month..Date.current.end_of_month)
             .sum(:amount)
  end

  # Next payment due date (1st of next month, or first_payment_date if in the future)
  def next_payment_date
    if first_payment_date.present? && first_payment_date > Date.current
      first_payment_date
    else
      Date.current.next_month.beginning_of_month
    end
  end

  # Total amount owed at a specific date — from ledger running balance
  def balance_as_of(date)
    loan_ledger_entries.where("effective_date <= ?", date).order(id: :desc).pick(:running_balance) || BigDecimal("0")
  end

  # Principal balance only (for interest calculations — don't charge interest on interest)
  def principal_balance_as_of(date)
    loan_ledger_entries.principal_affecting.where("effective_date <= ?", date).sum(:amount)
  end

  # Ensure monthly interest accruals are posted for each completed month since origination.
  # Accrual is posted on the last day of each month (or origination_date for the first partial month).
  # Idempotent — skips months that already have an accrual entry.
  # Only accrues from the loan's created_at date forward to avoid incorrect retroactive accruals
  # (e.g. interest-only loans where principal was paid down before the loan entered the system).
  def accrue_interest_if_needed
    return unless status == "active"

    last_month_end = (Date.current - 1).end_of_month
    # If we haven't finished the current month yet, go back to previous month end
    last_month_end = last_month_end.prev_month.end_of_month if last_month_end >= Date.current

    # Only accrue from the month the loan was entered into the system, not from origination
    earliest_accrual_date = [origination_date, created_at.to_date].max

    # Build list of month-end dates from earliest accrual date through last completed month
    accrual_dates = []
    date = earliest_accrual_date.end_of_month
    while date <= last_month_end
      accrual_dates << date
      date = date.next_month.end_of_month
    end
    return if accrual_dates.empty?

    # Find which months already have accruals
    existing_dates = loan_ledger_entries
      .where(entry_type: "interest_accrual")
      .pluck(:effective_date)
      .to_set

    missing_dates = accrual_dates.reject { |d| existing_dates.include?(d) }
    return if missing_dates.empty?

    service = LoanLedger::PostingService.new(self)

    missing_dates.each do |month_end|
      month_start = [month_end.beginning_of_month, earliest_accrual_date].max
      days_in_period = (month_end - month_start).to_i + 1

      balance = principal_balance_as_of(month_end)
      next if balance <= 0

      interest = monthly_interest_for_period(balance, days_in_period, month_end, period_start: month_start)
      next if interest <= 0

      service.post!({
        entry_type: "interest_accrual",
        effective_date: month_end,
        amount: interest,
        description: "Interest accrual - #{month_start.strftime('%b %Y')}",
        metadata: {
          balance: balance.to_f,
          rate: effective_interest_rate.to_f,
          calc_method: interest_calc_method,
          days: days_in_period
        }
      })
    end
  end

  # Calculate interest for a specific period based on calc method
  def monthly_interest_for_period(balance, days, date, period_start: nil)
    rate = effective_interest_rate / 100
    case interest_calc_method
    when "30_360"
      # 30/360 (US NASD): each month is treated as 30 days, year as 360
      if period_start
        thirty_360_days = calc_30_360_days(period_start, date)
      else
        thirty_360_days = 30
      end
      (balance * rate * thirty_360_days / 360).round(2)
    when "actual_360"
      # Actual days in period / 360-day year
      (balance * rate * days / 360).round(2)
    when "actual_365"
      # Actual days in period / 365-day year
      (balance * rate * days / 365).round(2)
    end
  end

  # 30/360 US day count convention
  def calc_30_360_days(start_date, end_date)
    # Full calendar month (1st to end of same month) = 30 days
    if start_date.day == 1 && end_date == end_date.end_of_month &&
       start_date.month == end_date.month && start_date.year == end_date.year
      return 30
    end

    d1 = [start_date.day, 30].min
    d2 = end_date.day
    d2 = 30 if d2 == 31 && d1 >= 30
    d2 = 30 if end_date.month == 2 && end_date == end_date.end_of_month
    (end_date.year - start_date.year) * 360 + (end_date.month - start_date.month) * 30 + (d2 - d1)
  end

  def display_name
    "#{borrower_name} - #{property_address}"
  end

  private

  def post_disbursement_to_ledger
    LoanLedger::PostingService.new(self).post!({
      entry_type: "disbursement",
      effective_date: origination_date,
      amount: loan_amount,
      description: "Initial loan disbursement"
    })
  end
end
