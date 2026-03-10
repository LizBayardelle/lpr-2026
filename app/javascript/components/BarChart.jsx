import React from "react"

export default function BarChart({ title, data }) {
  const maxValue = Math.max(...data.map((d) => d.value))

  return (
    <div>
      {title && <div className="text-xs font-bold uppercase tracking-[0.15em] text-[#8a8f9a] mb-4">{title}</div>}
      <div style={{ display: "flex", alignItems: "flex-end", gap: "6px", height: "160px" }}>
        {data.map((d, i) => {
          const heightPct = maxValue > 0 ? (d.value / maxValue) * 100 : 0
          return (
            <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", height: "100%", justifyContent: "flex-end" }}>
              <div className="text-xs font-semibold text-[#1a1a1a] mb-1">{d.value}</div>
              <div
                className={i % 2 === 0 ? "chart-bar" : "chart-bar-alt"}
                style={{ width: "100%", height: `${heightPct}%`, minHeight: "2px", transition: "height 0.3s ease" }}
              />
              <div className="text-[10px] text-[#8a8f9a] mt-2 uppercase tracking-wider">{d.label}</div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
