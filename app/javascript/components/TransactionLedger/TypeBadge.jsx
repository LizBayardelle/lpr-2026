import React from "react"
import { TYPE_COLORS, ENTRY_TYPE_LABELS } from "./ledgerUtils"

export default function TypeBadge({ entryType, reversed, reversal }) {
  const color = TYPE_COLORS[entryType] || "neutral"
  const label = ENTRY_TYPE_LABELS[entryType] || entryType.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())

  return (
    <span style={{ whiteSpace: "nowrap" }}>
      <span className={`badge badge-${color}`}>{label}</span>
      {reversed && <span className="badge badge-danger" style={{ marginLeft: "0.25rem" }}>Reversed</span>}
      {reversal && <span className="badge badge-neutral" style={{ marginLeft: "0.25rem" }}>Reversal</span>}
    </span>
  )
}
