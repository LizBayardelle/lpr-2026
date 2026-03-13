import React, { useState, useCallback, useRef } from "react"
import LedgerRow from "./LedgerRow"
import AddEntryRow from "./AddEntryRow"
import PostInterestModal from "./PostInterestModal"
import PostAdjustmentModal from "./PostAdjustmentModal"
import { rebalance, apiRequest } from "./ledgerUtils"

export default function TransactionLedger({ entries: initialEntries, loan, godpowers, basePath }) {
  const [entries, setEntries] = useState(() => rebalance(initialEntries))
  const [sortDir, setSortDir] = useState("asc")
  const [modal, setModal] = useState(null) // "interest" | "adjustment" | null
  const [flash, setFlash] = useState(null)
  const tableRef = useRef(null)

  const showFlash = (msg, type = "notice") => {
    setFlash({ msg, type })
    setTimeout(() => setFlash(null), 4000)
  }

  const sorted = sortDir === "asc" ? entries : [...entries].reverse()

  // --- Entry mutations ---

  const handleUpdate = useCallback(async (entryId, attrs) => {
    // Optimistic update
    setEntries(prev => {
      const updated = prev.map(e => {
        if (e.id !== entryId) return e
        const copy = { ...e }
        if (attrs.effective_date) copy.effectiveDate = attrs.effective_date
        if (attrs.description !== undefined) copy.description = attrs.description
        if (attrs.amount !== undefined) copy.amount = attrs.amount
        return copy
      })
      return rebalance(updated)
    })

    try {
      const data = await apiRequest(`${basePath}/${entryId}`, "PATCH", attrs)
      if (data?.entries) setEntries(rebalance(data.entries))
    } catch (err) {
      showFlash(err.message, "alert")
      // Reload from server on error
      reloadEntries()
    }
  }, [basePath])

  const handleReverse = useCallback(async (entryId) => {
    try {
      const data = await apiRequest(`${basePath}/${entryId}/reverse`, "POST")
      if (data?.entries) {
        setEntries(rebalance(data.entries))
        showFlash("Entry reversed.")
      }
    } catch (err) {
      showFlash(err.message, "alert")
    }
  }, [basePath])

  const handleDelete = useCallback(async (entryId) => {
    // Optimistic removal
    setEntries(prev => rebalance(prev.filter(e => e.id !== entryId)))

    try {
      const data = await apiRequest(`${basePath}/${entryId}`, "DELETE")
      if (data?.entries) setEntries(rebalance(data.entries))
      showFlash("Entry deleted.")
    } catch (err) {
      showFlash(err.message, "alert")
      reloadEntries()
    }
  }, [basePath])

  const handleAdd = useCallback(async ({ entryType, effectiveDate, amount, description }) => {
    try {
      const data = await apiRequest(basePath, "POST", {
        entry_type: entryType,
        effective_date: effectiveDate,
        amount: amount,
        description: description || `${entryType.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())}`,
      })
      if (data?.entries) {
        setEntries(rebalance(data.entries))
        showFlash("Entry added.")
      }
    } catch (err) {
      showFlash(err.message, "alert")
      throw err
    }
  }, [basePath])

  const handlePostInterest = useCallback(async ({ periodStart, periodEnd }) => {
    const data = await apiRequest(`${basePath}/accrue_interest`, "POST", {
      period_start: periodStart,
      period_end: periodEnd,
    })
    if (data?.entries) {
      setEntries(rebalance(data.entries))
      showFlash(data.notice || "Interest accrual posted.")
    }
  }, [basePath])

  const handlePostAdjustment = useCallback(async ({ effectiveDate, amount, description, principalAffecting }) => {
    const data = await apiRequest(basePath, "POST", {
      entry_type: principalAffecting ? "adjustment_principal" : "adjustment",
      effective_date: effectiveDate,
      amount: amount,
      description: description,
    })
    if (data?.entries) {
      setEntries(rebalance(data.entries))
      showFlash("Adjustment posted.")
    }
  }, [basePath])

  const reloadEntries = async () => {
    try {
      const data = await apiRequest(`${basePath}?format=json`, "GET")
      if (data?.entries) setEntries(rebalance(data.entries))
    } catch { /* ignore */ }
  }

  // Tab navigation across rows
  const handleTabToNext = useCallback((fromRowIndex, fieldIndex, direction) => {
    if (!tableRef.current) return
    const rows = tableRef.current.querySelectorAll("tbody tr")
    const targetRowIdx = fromRowIndex + direction
    if (targetRowIdx < 0 || targetRowIdx >= rows.length) return
    const fields = ["date", "description", "debit", "credit"]
    const targetRow = rows[targetRowIdx]
    const cell = targetRow.querySelector(`[data-field="${fields[fieldIndex]}"]`)
    if (cell && cell.__startEditing) cell.__startEditing()
  }, [])

  const toggleSort = () => setSortDir(d => d === "asc" ? "desc" : "asc")

  return (
    <div>
      {flash && (
        <div
          data-flash
          style={{
            padding: "0.75rem 1.25rem", marginBottom: "1rem", borderRadius: "6px", fontSize: "0.875rem",
            background: flash.type === "alert" ? "#fef2f2" : "#f0fdf4",
            color: flash.type === "alert" ? "#991b1b" : "#166534",
            border: `1px solid ${flash.type === "alert" ? "#fecaca" : "#bbf7d0"}`,
          }}
        >
          {flash.msg}
        </div>
      )}

      <div className="card" style={{ padding: 0, marginTop: "1.5rem" }}>
        {/* Fixed sidebar actions */}
        <div style={{
          position: "fixed", left: 0, top: "50%", transform: "translateY(-50%)",
          zIndex: 100, display: "flex", flexDirection: "column", gap: "2px",
        }}>
          <a href="#" onClick={e => { e.preventDefault(); document.getElementById("new-payment-modal")?.classList.add("active") }} title="Record Payment" style={{
            display: "flex", alignItems: "center", justifyContent: "center",
            width: "40px", height: "40px", background: "var(--color-navy)", color: "#fff",
            fontSize: "18px", textDecoration: "none", borderRadius: "0 6px 6px 0",
          }}>&#x0024;</a>
          <a href="#" onClick={e => { e.preventDefault(); setModal("interest") }} title="Post Interest" style={{
            display: "flex", alignItems: "center", justifyContent: "center",
            width: "40px", height: "40px", background: "var(--color-navy)", color: "#fff",
            fontSize: "18px", textDecoration: "none", borderRadius: "0 6px 6px 0",
          }}>&#x25D4;</a>
          <a href="#" onClick={e => { e.preventDefault(); setModal("adjustment") }} title="Post Adjustment" style={{
            display: "flex", alignItems: "center", justifyContent: "center",
            width: "40px", height: "40px", background: "var(--color-navy)", color: "#fff",
            fontSize: "18px", textDecoration: "none", borderRadius: "0 6px 6px 0",
          }}>&#x270E;</a>
        </div>

        <div style={{ padding: "1.5rem 2rem 0" }}>
          <h3 className="heading-3">Transaction Ledger</h3>
        </div>
        <div className="table-container" style={{ padding: "1rem 0 0" }}>
          <table ref={tableRef} className="data-table" style={{ minWidth: "1000px" }}>
            <thead>
              <tr>
                <th style={{ paddingLeft: "2rem" }}>
                  <span onClick={toggleSort} style={{ color: "inherit", cursor: "pointer", display: "inline-flex", alignItems: "center", gap: "0.25rem" }}>
                    Date <span style={{ fontSize: "0.625rem" }}>{sortDir === "desc" ? "▾" : "▴"}</span>
                  </span>
                </th>
                <th>Type</th>
                <th>Description</th>
                <th className="text-right">Debit</th>
                <th className="text-right">Credit</th>
                <th className="text-right">Amount Owed</th>
                <th className="text-right">Mo. Interest</th>
                <th style={{ paddingRight: godpowers ? 0 : "2rem" }}>Actions</th>
                {godpowers && <th style={{ width: "1rem" }}></th>}
              </tr>
            </thead>
            <tbody>
              {sorted.map((entry, i) => (
                <LedgerRow
                  key={entry.id}
                  entry={entry}
                  loan={loan}
                  godpowers={godpowers}
                  rowIndex={i}
                  onUpdate={handleUpdate}
                  onReverse={handleReverse}
                  onDelete={handleDelete}
                  onTabToNext={handleTabToNext}
                />
              ))}
              <AddEntryRow onAdd={handleAdd} godpowers={godpowers} />
            </tbody>
          </table>
        </div>
        {entries.length === 0 && (
          <div style={{ padding: "2rem", textAlign: "center", color: "var(--color-steel)", fontSize: "0.875rem" }}>
            No ledger entries yet. Entries are created automatically when payments, draws, and fees are recorded.
          </div>
        )}
      </div>

      {modal === "interest" && (
        <PostInterestModal loan={loan} onPost={handlePostInterest} onClose={() => setModal(null)} />
      )}
      {modal === "adjustment" && (
        <PostAdjustmentModal onPost={handlePostAdjustment} onClose={() => setModal(null)} />
      )}
    </div>
  )
}
