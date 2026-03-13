import React, { useState, useRef, useEffect, useCallback } from "react"

export default function EditableCell({ value, displayValue, type, sign, onSave, onTab, style }) {
  const [editing, setEditing] = useState(false)
  const [editValue, setEditValue] = useState("")
  const inputRef = useRef(null)
  const cellRef = useRef(null)

  useEffect(() => {
    if (editing && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [editing])

  const startEditing = useCallback(() => {
    const v = type === "number" ? parseFloat(value).toFixed(2) : value
    setEditValue(v)
    setEditing(true)
  }, [value, type])

  // Expose startEditing via the cell ref for tab navigation
  useEffect(() => {
    if (cellRef.current) {
      cellRef.current.__startEditing = startEditing
    }
  }, [startEditing])

  const save = () => {
    setEditing(false)
    let newVal = editValue
    if (type === "number") {
      newVal = newVal.replace(/[^0-9.\-]/g, "")
      if (parseFloat(newVal) === parseFloat(value)) return
      const sendVal = (parseFloat(newVal) * (sign || 1)).toString()
      onSave(sendVal)
    } else {
      if (newVal === value) return
      onSave(newVal)
    }
  }

  const cancel = () => {
    setEditing(false)
  }

  const handleKeyDown = (e) => {
    if (e.key === "Enter") { e.preventDefault(); save(); if (onTab) setTimeout(() => onTab(e.shiftKey), 0) }
    if (e.key === "Escape") { e.preventDefault(); cancel() }
    if (e.key === "Tab") {
      e.preventDefault()
      save()
      if (onTab) setTimeout(() => onTab(e.shiftKey), 0)
    }
  }

  if (editing) {
    return (
      <td ref={cellRef} style={style}>
        <input
          ref={inputRef}
          type={type === "date" ? "date" : "text"}
          inputMode={type === "number" ? "decimal" : undefined}
          value={editValue}
          onChange={e => setEditValue(e.target.value)}
          onKeyDown={handleKeyDown}
          onBlur={save}
          style={{
            fontSize: "inherit", fontFamily: "inherit", padding: "2px 4px",
            border: "1px solid var(--color-navy)", borderRadius: "3px", outline: "none",
            width: "100%", boxSizing: "border-box",
            textAlign: type === "number" ? "right" : "left",
          }}
        />
      </td>
    )
  }

  return (
    <td ref={cellRef} style={style}>
      {displayValue != null && displayValue !== "" ? (
        onSave ? (
          <span
            onClick={startEditing}
            style={{ cursor: "pointer", borderBottom: "1px dashed var(--color-concrete)" }}
          >
            {displayValue}
          </span>
        ) : (
          <span>{displayValue}</span>
        )
      ) : null}
    </td>
  )
}
