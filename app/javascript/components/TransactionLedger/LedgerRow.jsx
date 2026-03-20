import React, { useRef, useState } from "react"
import EditableCell from "./EditableCell"
import TypeBadge from "./TypeBadge"
import { formatCurrency, formatDate, monthlyInterestDue, MEMO_TYPES } from "./ledgerUtils"

const EDITABLE_FIELDS = ["date", "description", "debit", "credit"]

export default function LedgerRow({ entry, loan, godpowers, onUpdate, onReverse, onDelete, onTabToNext, rowIndex }) {
  const rowRef = useRef(null)
  const [highlighted, setHighlighted] = useState(false)

  const handleRowClick = (e) => {
    // Don't highlight if clicking on an editable cell, button, or input
    const target = e.target
    if (target.closest("button, input, select, textarea, [data-field]")) return
    setHighlighted(h => !h)
  }

  const reversed = !!entry.reversedById
  const reversal = !!entry.reversalOfId
  const isMemo = MEMO_TYPES.includes(entry.entryType)
  const isDebit = parseFloat(entry.amount) > 0
  const isCredit = parseFloat(entry.amount) < 0
  const isPayment = entry.entryType.startsWith("payment_")
  const moInterest = monthlyInterestDue(entry.principalAtEntry, loan.interestRate, loan.interestCalcMethod)

  if (isMemo) {
    const colSpan = godpowers ? 9 : 8
    const isWithholding = entry.entryType === "reserve_withholding"
    const isGenericMemo = entry.entryType === "memo"
    const amtLabel = formatCurrency(Math.abs(parseFloat(entry.amount)))
    const fallback = isGenericMemo ? "" : isWithholding ? `${amtLabel} reserve established` : `Reserve released — ${amtLabel}`
    const showDelete = isGenericMemo || godpowers
    return (
      <tr ref={rowRef} style={{ background: "var(--color-smoke)" }}>
        <td style={{ whiteSpace: "nowrap", paddingLeft: "2rem", color: "var(--color-steel)", fontSize: "0.8125rem" }}>{formatDate(entry.effectiveDate)}</td>
        <td style={{ whiteSpace: "nowrap" }}>
          <TypeBadge entryType={entry.entryType} reversed={reversed} reversal={reversal} />
        </td>
        <td colSpan={5} style={{ fontSize: "0.8125rem", color: "var(--color-steel)" }}>{entry.description || fallback}</td>
        <td style={{ textAlign: "right", paddingRight: godpowers || isGenericMemo ? 0 : "2rem" }}>
          {!isGenericMemo && !reversed && !reversal && (
            <button
              onClick={() => { if (confirm("Reverse this entry?")) onReverse(entry.id) }}
              className="btn-filled btn-filled-danger"
              style={{ fontSize: "10px", padding: "2px 8px" }}
            >Reverse</button>
          )}
          {!isGenericMemo && reversed && <span className="badge badge-danger">Reversed</span>}
        </td>
        {showDelete && (
          <td style={{ textAlign: "center", verticalAlign: "middle" }}>
            <button
              onClick={() => { if (confirm(isGenericMemo ? "Delete this memo?" : "Delete this entry?")) onDelete(entry.id) }}
              style={{ background: "none", border: "none", cursor: "pointer", color: "#ccc", fontSize: "14px", padding: "2px 4px", lineHeight: 1 }}
            >&#x2715;</button>
          </td>
        )}
      </tr>
    )
  }

  const makeTabHandler = (fieldIndex) => (shiftKey) => {
    const row = rowRef.current
    if (!row) return
    const dir = shiftKey ? -1 : 1
    const nextFieldIdx = fieldIndex + dir

    // Try next/prev cell in same row
    if (nextFieldIdx >= 0 && nextFieldIdx < EDITABLE_FIELDS.length) {
      const cell = row.querySelector(`[data-field="${EDITABLE_FIELDS[nextFieldIdx]}"]`)
      if (cell && cell.__startEditing) { cell.__startEditing(); return }
    }

    // Move to next/prev row
    if (onTabToNext) onTabToNext(rowIndex, nextFieldIdx < 0 ? EDITABLE_FIELDS.length - 1 : 0, dir)
  }

  return (
    <tr ref={rowRef} onClick={handleRowClick} style={{ opacity: reversed ? 0.5 : 1, background: highlighted ? "rgba(30, 58, 95, 0.06)" : undefined, cursor: "default" }}>
      <EditableCell
        value={entry.effectiveDate}
        displayValue={formatDate(entry.effectiveDate)}
        type="date"
        onSave={(val) => onUpdate(entry.id, { effective_date: val })}
        onTab={makeTabHandler(0)}
        style={{ whiteSpace: "nowrap", paddingLeft: "2rem" }}
      />
      <td style={{ whiteSpace: "nowrap" }}>
        <TypeBadge entryType={entry.entryType} reversed={reversed} reversal={reversal} />
      </td>
      <EditableCell
        value={entry.description}
        displayValue={entry.description}
        type="text"
        onSave={(val) => onUpdate(entry.id, { description: val })}
        onTab={makeTabHandler(1)}
        style={{ fontSize: "0.8125rem" }}
      />
      <EditableCell
        value={isDebit ? entry.amount : ""}
        displayValue={isDebit ? formatCurrency(entry.amount) : ""}
        type="number"
        sign={1}
        onSave={!isPayment ? (val) => onUpdate(entry.id, { amount: val }) : null}
        onTab={makeTabHandler(2)}
        style={{ textAlign: "right", fontVariantNumeric: "tabular-nums" }}
      />
      <EditableCell
        value={isCredit ? Math.abs(parseFloat(entry.amount)).toString() : ""}
        displayValue={isCredit ? formatCurrency(Math.abs(parseFloat(entry.amount))) : ""}
        type="number"
        sign={-1}
        onSave={!isPayment ? (val) => onUpdate(entry.id, { amount: val }) : null}
        onTab={makeTabHandler(3)}
        style={{ textAlign: "right", fontVariantNumeric: "tabular-nums" }}
      />
      <td className="text-money" style={{ fontWeight: 500 }}>{formatCurrency(entry.runningBalance)}</td>
      <td className="text-money" style={{ color: "var(--color-steel)", position: "relative" }}>
        <span className="ledger-tooltip-trigger" style={{ cursor: "help" }}>
          {formatCurrency(moInterest)}
          <span className="ledger-tooltip">Principal: {formatCurrency(entry.principalAtEntry)}</span>
        </span>
      </td>
      <td style={{ paddingRight: godpowers ? 0 : "2rem" }}>
        {!reversed && !reversal && (
          <button
            onClick={() => { if (confirm("Reverse this ledger entry? This will post an offsetting entry.")) onReverse(entry.id) }}
            className="btn-filled btn-filled-danger"
            style={{ fontSize: "11px", padding: "4px 10px" }}
          >Reverse</button>
        )}
      </td>
      {godpowers && (
        <td style={{ textAlign: "center", verticalAlign: "middle" }}>
          <button
            onClick={() => { if (confirm("Permanently delete this ledger entry? This cannot be undone and will recalculate all balances.")) onDelete(entry.id) }}
            style={{ background: "none", border: "none", cursor: "pointer", color: "#ccc", fontSize: "14px", padding: "2px 4px", lineHeight: 1 }}
          >&#x2715;</button>
        </td>
      )}
    </tr>
  )
}
