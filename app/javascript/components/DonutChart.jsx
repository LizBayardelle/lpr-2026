import React from "react"

export default function DonutChart({ title, data, size = 160 }) {
  const total = data.reduce((sum, d) => sum + d.value, 0)
  const radius = (size - 20) / 2
  const cx = size / 2
  const cy = size / 2
  const strokeWidth = 24

  const colors = ["#031d55", "#1a1a1a", "#8a8f9a", "#c4c7cc"]
  let cumulative = 0

  const segments = data.map((d, i) => {
    const startAngle = (cumulative / total) * 2 * Math.PI - Math.PI / 2
    cumulative += d.value
    const endAngle = (cumulative / total) * 2 * Math.PI - Math.PI / 2

    const largeArc = d.value / total > 0.5 ? 1 : 0
    const x1 = cx + radius * Math.cos(startAngle)
    const y1 = cy + radius * Math.sin(startAngle)
    const x2 = cx + radius * Math.cos(endAngle)
    const y2 = cy + radius * Math.sin(endAngle)

    return (
      <path
        key={i}
        d={`M ${x1} ${y1} A ${radius} ${radius} 0 ${largeArc} 1 ${x2} ${y2}`}
        fill="none"
        stroke={colors[i % colors.length]}
        strokeWidth={strokeWidth}
      />
    )
  })

  return (
    <div>
      {title && <div className="text-xs font-bold uppercase tracking-[0.15em] text-[#8a8f9a] mb-4">{title}</div>}
      <div style={{ display: "flex", alignItems: "center", gap: "24px" }}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
          {segments}
        </svg>
        <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
          {data.map((d, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <div style={{ width: "8px", height: "8px", borderRadius: "50%", backgroundColor: colors[i % colors.length], flexShrink: 0 }} />
              <span className="text-xs text-[#8a8f9a]">{d.label}</span>
              <span className="text-xs font-semibold text-[#1a1a1a]">{d.value}%</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
