class LoanStatement < ApplicationRecord
  belongs_to :loan
  has_one_attached :pdf

  validates :statement_date, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :beginning_balance, presence: true
  validates :ending_balance, presence: true
  validates :interest_due, presence: true
  validates :total_due, presence: true
  scope :recent, -> { order(created_at: :desc) }
  scope :for_year, ->(year) { where(statement_date: Date.new(year, 1, 1)..Date.new(year, 12, 31)) }

  # True if underlying data changed OR a newer statement covers the same period
  def stale?
    cutoff = created_at
    range = period_start..period_end

    # A newer statement exists for an overlapping period
    loan.loan_statements
      .where("id != ? AND period_start <= ? AND period_end >= ? AND created_at > ?", id, period_end, period_start, cutoff)
      .exists? ||
    # Underlying data changed since generation
    loan.payments.for_period(period_start, period_end).where("payments.created_at > :t OR payments.updated_at > :t", t: cutoff).exists? ||
      loan.loan_draws.funded.where(draw_date: range).where("loan_draws.created_at > :t OR loan_draws.updated_at > :t", t: cutoff).exists? ||
      loan.loan_fees.where(fee_date: range).where("loan_fees.created_at > :t OR loan_fees.updated_at > :t", t: cutoff).exists?
  end

  # Generate a statement for a loan.
  # Accepts either a single date (uses that month) or explicit period_start/period_end.
  # Always creates a new statement — older ones for the same period get marked stale automatically.
  def self.generate_for_loan(loan, date = Date.current, period_start: nil, period_end: nil)
    period_start ||= date.beginning_of_month
    period_end   ||= date.end_of_month
    statement_date = period_end

    # Calculate balances ad hoc from payment/draw history
    principal_paid_before = loan.payments.where("payment_date < ?", period_start).sum(:principal_amount)
    draws_before = loan.loan_draws.funded.where("draw_date < ?", period_start).sum(:amount)
    beginning_balance = loan.loan_amount + draws_before - principal_paid_before

    # Payments received during this period
    period_payments = loan.payments.for_period(period_start, period_end)
    payments_total = period_payments.sum(:amount)
    period_principal_paid = period_payments.sum(:principal_amount)

    # Draws funded during this period
    period_draws = loan.loan_draws.funded.where(draw_date: period_start..period_end).sum(:amount)

    # Calculate interest pro-rated by days in period
    days_in_period = (period_end - period_start).to_i + 1
    interest_due = (loan.daily_interest(beginning_balance) * days_in_period).round(2)
    principal_due = loan.payment_type == "interest_only" ? 0 : loan.monthly_payment_amount - interest_due
    principal_due = [principal_due, 0].max
    total_due = interest_due + principal_due
    ending_balance = beginning_balance + period_draws - period_principal_paid

    # Past due: total owed minus total paid through this period
    past_due = [total_due - payments_total, 0].max

    # Late fee
    late_fee = 0
    if past_due > 0 && loan.grace_period_days.present?
      late_fee = loan.calculate_late_fee(past_due)
    end

    loan.loan_statements.create!(
      statement_date: statement_date,
      period_start: period_start,
      period_end: period_end,
      beginning_balance: beginning_balance,
      ending_balance: ending_balance,
      interest_due: interest_due,
      principal_due: principal_due,
      total_due: total_due,
      payments_received: payments_total,
      late_fee: late_fee,
      past_due_amount: past_due
    )
  end
end
