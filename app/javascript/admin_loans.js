// Modal management
document.addEventListener("click", (e) => {
  const trigger = e.target.closest("[data-modal-target]")
  if (trigger) {
    e.preventDefault()
    const modal = document.getElementById(trigger.dataset.modalTarget)
    if (modal) modal.classList.add("active")
  }

  if (e.target.classList.contains("modal-overlay")) {
    e.target.classList.remove("active")
  }

  const close = e.target.closest("[data-modal-close]")
  if (close) {
    const overlay = close.closest(".modal-overlay")
    if (overlay) overlay.classList.remove("active")
  }
})

// Origination fee type toggle — show percent or flat field
document.addEventListener("change", (e) => {
  const select = e.target.closest("[data-fee-type-toggle]")
  if (!select) return

  const container = select.closest(".wizard-panel, .modal-body, form")
  if (!container) return

  const percentField = container.querySelector('[data-fee-field="percent"]')
  const flatField = container.querySelector('[data-fee-field="flat"]')
  if (!percentField || !flatField) return

  if (select.value === "flat") {
    percentField.style.display = "none"
    flatField.style.display = ""
  } else {
    percentField.style.display = ""
    flatField.style.display = "none"
  }
})

// Close modal on Escape
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") {
    document.querySelectorAll(".modal-overlay.active").forEach(m => m.classList.remove("active"))
  }
})

// Tab switching — persist active tab in URL ?tab= param
document.addEventListener("click", (e) => {
  const tab = e.target.closest("[data-tab]")
  if (!tab) return

  const container = tab.closest("[data-tabs]")
  if (!container) return

  // Deactivate all tabs and panels in this container
  container.querySelectorAll("[data-tab]").forEach(t => t.classList.remove("active"))
  container.querySelectorAll("[data-tab-panel]").forEach(p => p.classList.remove("active"))

  // Activate clicked tab and its panel
  tab.classList.add("active")
  const panel = container.querySelector(`[data-tab-panel="${tab.dataset.tab}"]`)
  if (panel) panel.classList.add("active")

  // Update URL param without reload
  const url = new URL(window.location)
  url.searchParams.set("tab", tab.dataset.tab)
  history.replaceState(null, "", url)
})

// Wizard step navigation
document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-wizard-nav]")
  if (!btn) return
  e.preventDefault()

  const wizard = btn.closest("[data-wizard]")
  if (!wizard) return

  const direction = btn.dataset.wizardNav
  const panels = Array.from(wizard.querySelectorAll("[data-wizard-panel]"))
  const steps = Array.from(wizard.querySelectorAll("[data-wizard-step]"))
  const currentIdx = panels.findIndex(p => p.classList.contains("active"))

  let nextIdx
  if (direction === "next") {
    nextIdx = Math.min(currentIdx + 1, panels.length - 1)
  } else if (direction === "prev") {
    nextIdx = Math.max(currentIdx - 1, 0)
  } else {
    nextIdx = parseInt(direction, 10)
    if (isNaN(nextIdx)) return
  }

  panels.forEach(p => p.classList.remove("active"))
  steps.forEach(s => s.classList.remove("active"))

  panels[nextIdx].classList.add("active")
  steps[nextIdx].classList.add("active")

  // Mark previous steps as completed
  steps.forEach((s, i) => {
    if (i < nextIdx) {
      s.classList.add("completed")
    } else {
      s.classList.remove("completed")
    }
  })
})

// Clicking a wizard step indicator
document.addEventListener("click", (e) => {
  const step = e.target.closest("[data-wizard-step]")
  if (!step) return

  const wizard = step.closest("[data-wizard]")
  if (!wizard) return

  const steps = Array.from(wizard.querySelectorAll("[data-wizard-step]"))
  const panels = Array.from(wizard.querySelectorAll("[data-wizard-panel]"))
  const idx = steps.indexOf(step)

  panels.forEach(p => p.classList.remove("active"))
  steps.forEach(s => s.classList.remove("active"))

  panels[idx].classList.add("active")
  steps[idx].classList.add("active")

  steps.forEach((s, i) => {
    if (i < idx) {
      s.classList.add("completed")
    } else {
      s.classList.remove("completed")
    }
  })
})

// Reset wizard to step 1 when modal closes
document.addEventListener("click", (e) => {
  const isOverlayClick = e.target.classList.contains("modal-overlay")
  const isCloseBtn = e.target.closest("[data-modal-close]")
  if (!isOverlayClick && !isCloseBtn) return

  const overlay = isOverlayClick ? e.target : e.target.closest(".modal-overlay")
  if (!overlay) return

  const wizard = overlay.querySelector("[data-wizard]")
  if (!wizard) return

  // Delay reset so it happens after close animation
  setTimeout(() => {
    const panels = wizard.querySelectorAll("[data-wizard-panel]")
    const steps = wizard.querySelectorAll("[data-wizard-step]")
    panels.forEach((p, i) => p.classList.toggle("active", i === 0))
    steps.forEach((s, i) => {
      s.classList.toggle("active", i === 0)
      s.classList.remove("completed")
    })
  }, 250)
})

// Populate wizard review panel when navigating to it
function populateWizardReview(wizard) {
  const form = wizard.closest("form") || wizard.querySelector("form")
  if (!form) return

  wizard.querySelectorAll("[data-review-field]").forEach(cell => {
    const fieldName = cell.dataset.reviewField
    const fmt = cell.dataset.reviewFormat

    // Special handling for origination fee (depends on fee type)
    if (fmt === "origination_fee") {
      const feeType = form.querySelector('[name="loan[origination_fee_type]"]')
      if (feeType && feeType.value === "flat") {
        const flatInput = form.querySelector('[name="loan[origination_fee_flat]"]')
        const val = flatInput ? flatInput.value : ""
        if (!val || val.trim() === "") {
          cell.textContent = "-"
          cell.style.color = "var(--color-concrete)"
        } else {
          const num = parseFloat(val)
          cell.textContent = isNaN(num) ? val : "$" + num.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + " flat"
          cell.style.color = ""
        }
      } else {
        const pctInput = form.querySelector('[name="loan[origination_fee_percent]"]')
        const val = pctInput ? pctInput.value : ""
        if (!val || val.trim() === "") {
          cell.textContent = "-"
          cell.style.color = "var(--color-concrete)"
        } else {
          cell.textContent = val + "%"
          cell.style.color = ""
        }
      }
      return
    }

    const input = form.querySelector(`[id="${fieldName}"], [name="loan[${fieldName.replace('loan_', '')}]"]`)
    if (!input) return

    let value = input.tagName === "SELECT"
      ? input.options[input.selectedIndex]?.text || ""
      : input.value

    if (!value || value.trim() === "") {
      cell.textContent = "-"
      cell.style.color = "var(--color-concrete)"
    } else {
      cell.style.color = ""
      if (fmt === "currency") {
        const num = parseFloat(value)
        cell.textContent = isNaN(num) ? value : "$" + num.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
      } else if (fmt === "percent") {
        cell.textContent = value + "%"
      } else if (fmt === "months") {
        cell.textContent = value + " months"
      } else if (fmt === "days") {
        cell.textContent = value + " days"
      } else if (fmt === "titleize") {
        cell.textContent = value.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())
      } else {
        cell.textContent = value
      }
    }
  })
}

// Hook into wizard navigation to trigger review population
const origClick = document.addEventListener
document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-wizard-nav]")
  const step = e.target.closest("[data-wizard-step]")
  if (!btn && !step) return

  const wizard = (btn || step).closest("[data-wizard]")
  if (!wizard) return

  // Small delay to let the panel switch happen first
  requestAnimationFrame(() => {
    const activePanel = wizard.querySelector("[data-wizard-panel].active")
    if (activePanel && activePanel.querySelector("[data-review-field]")) {
      populateWizardReview(wizard)
    }
  })
})

// Interest accrual month picker — populate date fields from month select
document.addEventListener("change", (e) => {
  const picker = e.target.closest("[data-interest-month-picker]")
  if (!picker) return

  const modal = picker.closest(".modal")
  const startInput = modal.querySelector("[data-interest-start]")
  const endInput = modal.querySelector("[data-interest-end]")
  const customRange = modal.querySelector("[data-interest-custom-range]")

  if (picker.value === "") {
    customRange.style.display = ""
    return
  }

  const [year, month] = picker.value.split("-").map(Number)
  const start = new Date(year, month - 1, 1)
  const end = new Date(year, month, 0) // last day of month

  const fmt = (d) => d.toISOString().split("T")[0]
  startInput.value = fmt(start)
  endInput.value = fmt(end)
  customRange.style.display = "none"
})

// Restore tab from URL on page load
document.addEventListener("DOMContentLoaded", () => {
  const params = new URLSearchParams(window.location.search)
  const activeTab = params.get("tab")
  if (!activeTab) return

  const container = document.querySelector("[data-tabs]")
  if (!container) return

  const tab = container.querySelector(`[data-tab="${activeTab}"]`)
  const panel = container.querySelector(`[data-tab-panel="${activeTab}"]`)
  if (!tab || !panel) return

  container.querySelectorAll("[data-tab]").forEach(t => t.classList.remove("active"))
  container.querySelectorAll("[data-tab-panel]").forEach(p => p.classList.remove("active"))
  tab.classList.add("active")
  panel.classList.add("active")
})
