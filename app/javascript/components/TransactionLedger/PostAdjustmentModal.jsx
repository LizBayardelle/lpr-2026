import React, { useState } from "react"

export default function PostAdjustmentModal({ onPost, onClose }) {
  const [date, setDate] = useState(new Date().toISOString().split("T")[0])
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")
  const [principalAffecting, setPrincipalAffecting] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!date || !amount || !description) return
    setSubmitting(true)
    try {
      await onPost({ effectiveDate: date, amount, description, principalAffecting })
      onClose()
    } catch (err) {
      alert(err.message)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="modal-overlay active" onClick={e => { if (e.target === e.currentTarget) onClose() }}>
      <div className="modal" style={{ maxWidth: "480px" }}>
        <div className="modal-header">
          <h3 className="heading-3">Post Manual Adjustment</h3>
          <button className="modal-close" onClick={onClose}>&times;</button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
            <div>
              <label className="field-label">Effective Date</label>
              <input type="date" className="field-input" value={date} onChange={e => setDate(e.target.value)} required />
            </div>
            <div>
              <label className="field-label">Amount</label>
              <input type="number" step="0.01" className="field-input" value={amount} onChange={e => setAmount(e.target.value)} required placeholder="Positive = debit, negative = credit" />
            </div>
            <div>
              <label className="field-label">Description</label>
              <input type="text" className="field-input" value={description} onChange={e => setDescription(e.target.value)} required placeholder="Reason for adjustment" />
            </div>
            <div>
              <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.8125rem", color: "var(--color-steel)", cursor: "pointer" }}>
                <input type="checkbox" checked={principalAffecting} onChange={e => setPrincipalAffecting(e.target.checked)} />
                Affects principal balance
              </label>
            </div>
          </div>
          <div className="modal-footer">
            <button type="submit" className="btn-filled btn-filled-primary" disabled={submitting || !date || !amount || !description}>
              {submitting ? "Posting..." : "Post Adjustment"}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
