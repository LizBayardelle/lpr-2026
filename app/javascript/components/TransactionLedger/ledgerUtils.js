export const PRINCIPAL_AFFECTING_TYPES = ["disbursement", "draw", "payment_principal", "adjustment_principal"]

// Memo types don't affect running balance — they're informational markers
export const MEMO_TYPES = ["reserve_withholding", "reserve_release", "memo"]

export const TYPE_COLORS = {
  disbursement: "navy", draw: "navy",
  interest_accrual: "warning",
  payment_principal: "success", payment_interest: "success", payment_late_fee: "success",
  fee_assessed: "danger", late_fee_assessed: "danger", extension_fee: "danger",
  fee_paid: "success",
  adjustment: "neutral", adjustment_principal: "neutral",
  reserve_withholding: "neutral", reserve_release: "neutral", memo: "neutral",
}

export const ENTRY_TYPE_LABELS = {
  disbursement: "Disbursement", draw: "Draw",
  interest_accrual: "Interest Accrual",
  payment_principal: "Payment Principal", payment_interest: "Payment Interest", payment_late_fee: "Payment Late Fee",
  fee_assessed: "Fee Assessed", late_fee_assessed: "Late Fee Assessed", extension_fee: "Extension Fee",
  fee_paid: "Fee Paid",
  adjustment: "Adjustment", adjustment_principal: "Adjustment (Principal)",
  reserve_withholding: "Reserve Established", reserve_release: "Reserve Released", memo: "Memo",
}

export const ADDABLE_TYPES = [
  { value: "adjustment", label: "Adjustment" },
  { value: "adjustment_principal", label: "Adjustment (Principal)" },
  { value: "disbursement", label: "Disbursement" },
  { value: "draw", label: "Draw" },
  { value: "interest_accrual", label: "Interest Accrual" },
  { value: "payment_principal", label: "Payment (Principal)" },
  { value: "payment_interest", label: "Payment (Interest)" },
  { value: "payment_late_fee", label: "Payment (Late Fee)" },
  { value: "fee_assessed", label: "Fee Assessed" },
  { value: "late_fee_assessed", label: "Late Fee Assessed" },
  { value: "extension_fee", label: "Extension Fee" },
  { value: "fee_paid", label: "Fee Paid" },
  { value: "memo", label: "Memo / Note" },
]

export function rebalance(entries) {
  const sorted = [...entries].sort((a, b) => {
    const dc = a.effectiveDate.localeCompare(b.effectiveDate)
    return dc !== 0 ? dc : a.id - b.id
  })
  let running = 0
  let principal = 0
  for (const entry of sorted) {
    const amt = parseFloat(entry.amount)
    const isMemo = MEMO_TYPES.includes(entry.entryType)
    if (!isMemo) running += amt
    entry.runningBalance = running.toFixed(2)
    if (PRINCIPAL_AFFECTING_TYPES.includes(entry.entryType)) {
      principal += amt
    }
    entry.principalAtEntry = principal.toFixed(2)
  }
  return sorted
}

export function monthlyInterestDue(principalBalance, interestRate, calcMethod) {
  const rate = interestRate / 100.0
  const balance = parseFloat(principalBalance)
  if (balance <= 0) return 0
  // For monthly interest display, always show a full month
  switch (calcMethod) {
    case "30_360": return round2(balance * rate / 12)
    case "actual_360": return round2(balance * rate * 30 / 360)
    case "actual_365": return round2(balance * rate * 30 / 365)
    default: return round2(balance * rate / 12)
  }
}

function round2(n) {
  return Math.round(n * 100) / 100
}

export function formatCurrency(val) {
  const n = typeof val === "string" ? parseFloat(val) : val
  if (isNaN(n)) return ""
  return "$" + n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

export function formatDate(isoDate) {
  const d = new Date(isoDate + "T00:00:00")
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
}

export function getCSRFToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content || ""
}

export async function apiRequest(url, method, body = null) {
  const opts = {
    method,
    headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": getCSRFToken() },
  }
  if (body) opts.body = JSON.stringify(body)
  const res = await fetch(url, opts)
  if (!res.ok) {
    const data = await res.json().catch(() => ({}))
    throw new Error(data.error || `Request failed (${res.status})`)
  }
  if (res.status === 204 || method === "DELETE") return null
  const text = await res.text()
  return text ? JSON.parse(text) : null
}
