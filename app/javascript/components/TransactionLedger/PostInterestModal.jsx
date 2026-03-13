import React, { useState, useEffect } from "react"

export default function PostInterestModal({ loan, onPost, onClose }) {
  const [selectedMonth, setSelectedMonth] = useState(loan.nextAccrualMonth || "")
  const [periodStart, setPeriodStart] = useState("")
  const [periodEnd, setPeriodEnd] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const showCustom = selectedMonth === ""

  // Build month options from origination to now
  const monthOptions = []
  const start = new Date(loan.originationDate + "T00:00:00")
  const now = new Date()
  let d = new Date(start.getFullYear(), start.getMonth(), 1)
  while (d <= now) {
    const val = d.toISOString().slice(0, 7)
    const label = d.toLocaleDateString("en-US", { month: "long", year: "numeric" })
    monthOptions.push({ value: val, label })
    d = new Date(d.getFullYear(), d.getMonth() + 1, 1)
  }

  useEffect(() => {
    if (selectedMonth) {
      const [y, m] = selectedMonth.split("-").map(Number)
      const s = new Date(y, m - 1, 1)
      const e = new Date(y, m, 0) // last day
      setPeriodStart(fmt(s))
      setPeriodEnd(fmt(e))
    }
  }, [selectedMonth])

  // Set defaults on mount
  useEffect(() => {
    if (loan.nextAccrualMonth) {
      setSelectedMonth(loan.nextAccrualMonth)
    }
  }, [])

  const fmt = (d) => d.toISOString().split("T")[0]

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!periodStart || !periodEnd) return
    setSubmitting(true)
    try {
      await onPost({ periodStart, periodEnd })
      onClose()
    } catch (err) {
      alert(err.message)
    } finally {
      setSubmitting(false)
    }
  }

  const calcMethod = (loan.interestCalcMethod || "30_360").replace(/_/g, "/")

  return (
    <div className="modal-overlay active" onClick={e => { if (e.target === e.currentTarget) onClose() }}>
      <div className="modal" style={{ maxWidth: "480px" }}>
        <div className="modal-header">
          <h3 className="heading-3">Post Interest Accrual</h3>
          <button className="modal-close" onClick={onClose}>&times;</button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ display: "flex", flexDirection: "column", gap: "1rem", paddingBottom: "1.5rem" }}>
            <p style={{ fontSize: "0.8125rem", color: "var(--color-steel)", margin: 0 }}>
              Calculates interest from the principal balance as of the period start date using the loan's rate ({loan.interestRate}%) and calculation method ({calcMethod}).
            </p>
            <div>
              <label className="field-label">For the Month of</label>
              <select
                className="field-input"
                value={selectedMonth}
                onChange={e => setSelectedMonth(e.target.value)}
              >
                <option value="">Custom range...</option>
                {monthOptions.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            {showCustom && (
              <div style={{ display: "flex", gap: "1rem" }}>
                <div style={{ flex: 1 }}>
                  <label className="field-label">Period Start</label>
                  <input type="date" className="field-input" value={periodStart} onChange={e => setPeriodStart(e.target.value)} required />
                </div>
                <div style={{ flex: 1 }}>
                  <label className="field-label">Period End</label>
                  <input type="date" className="field-input" value={periodEnd} onChange={e => setPeriodEnd(e.target.value)} required />
                </div>
              </div>
            )}
          </div>
          <div className="modal-footer">
            <button type="submit" className="btn-filled btn-filled-primary" disabled={submitting || !periodStart || !periodEnd}>
              {submitting ? "Posting..." : "Post Interest"}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
