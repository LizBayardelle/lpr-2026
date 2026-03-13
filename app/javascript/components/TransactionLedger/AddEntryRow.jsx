import React, { useState, useRef } from "react"
import { ADDABLE_TYPES } from "./ledgerUtils"

const CREDIT_TYPES = ["payment_interest", "payment_principal", "payment_late_fee", "fee_paid"]

export default function AddEntryRow({ onAdd, godpowers }) {
  const [entryType, setEntryType] = useState("")
  const [date, setDate] = useState(new Date().toISOString().split("T")[0])
  const [description, setDescription] = useState("")
  const [amount, setAmount] = useState("")
  const [principalAffecting, setPrincipalAffecting] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const typeRef = useRef(null)

  const reset = () => {
    setEntryType("")
    setDescription("")
    setAmount("")
    setPrincipalAffecting(false)
    if (typeRef.current) typeRef.current.focus()
  }

  const isCredit = CREDIT_TYPES.includes(entryType)
  const isAdjustment = entryType === "adjustment"
  const isPayment = entryType === "payment"

  const handleSubmit = async () => {
    if (!entryType || !date || !amount) return
    setSubmitting(true)
    try {
      let type = entryType
      if (type === "adjustment" && principalAffecting) type = "adjustment_principal"
      // "payment" is our convenience type — server splits into interest + principal
      if (type === "payment") type = "payment_interest"

      // Credits get sent as negative amounts
      const sendAmount = (isCredit || isPayment)
        ? (-Math.abs(parseFloat(amount))).toString()
        : amount

      await onAdd({ entryType: type, effectiveDate: date, amount: sendAmount, description })
      reset()
    } finally {
      setSubmitting(false)
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === "Enter") { e.preventDefault(); handleSubmit() }
  }

  return (
    <tr style={{ background: "var(--color-snow, #f9fafb)" }}>
      <td style={{ paddingLeft: "2rem" }}>
        <input
          type="date"
          value={date}
          onChange={e => setDate(e.target.value)}
          onKeyDown={handleKeyDown}
          style={{ fontSize: "0.75rem", padding: "3px 4px", border: "1px solid var(--color-concrete)", borderRadius: "3px", fontFamily: "inherit" }}
        />
      </td>
      <td>
        <select
          ref={typeRef}
          value={entryType}
          onChange={e => setEntryType(e.target.value)}
          style={{ fontSize: "0.75rem", padding: "3px 4px", border: "1px solid var(--color-concrete)", borderRadius: "3px", fontFamily: "inherit", minWidth: "120px" }}
        >
          <option value="">Type...</option>
          <option value="payment" style={{ fontWeight: 600 }}>Payment (auto-split)</option>
          <optgroup label="─────────" />
          {ADDABLE_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
        </select>
        {isAdjustment && (
          <label style={{ display: "flex", alignItems: "center", gap: "0.25rem", fontSize: "0.625rem", color: "var(--color-steel)", marginTop: "2px", cursor: "pointer" }}>
            <input type="checkbox" checked={principalAffecting} onChange={e => setPrincipalAffecting(e.target.checked)} />
            Principal
          </label>
        )}
        {isPayment && (
          <span style={{ fontSize: "0.625rem", color: "var(--color-steel)", display: "block", marginTop: "2px" }}>
            Splits interest / principal
          </span>
        )}
      </td>
      <td>
        <input
          type="text"
          value={description}
          onChange={e => setDescription(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Description"
          style={{ fontSize: "0.75rem", padding: "3px 4px", border: "1px solid var(--color-concrete)", borderRadius: "3px", width: "100%", boxSizing: "border-box", fontFamily: "inherit" }}
        />
      </td>
      <td>
        <input
          type="text"
          inputMode="decimal"
          value={amount}
          onChange={e => setAmount(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={isCredit || isPayment ? "Payment amt" : "Amount"}
          style={{ fontSize: "0.75rem", padding: "3px 4px", border: "1px solid var(--color-concrete)", borderRadius: "3px", width: "100%", boxSizing: "border-box", textAlign: "right", fontFamily: "inherit" }}
        />
      </td>
      <td></td>
      <td></td>
      <td></td>
      <td style={{ paddingRight: godpowers ? 0 : "2rem" }}>
        <button
          onClick={handleSubmit}
          disabled={submitting || !entryType || !date || !amount}
          className="btn-filled btn-filled-primary"
          style={{ fontSize: "11px", padding: "4px 10px", opacity: (!entryType || !date || !amount) ? 0.4 : 1 }}
        >Add</button>
      </td>
      {godpowers && <td></td>}
    </tr>
  )
}
