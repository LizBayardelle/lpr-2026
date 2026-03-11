// Entry point for the build script in your package.json
import "./navbar"
import "./react_mount"
import "./admin_loans"
import "./wysiwyg"

// Auto-dismiss flash messages
document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-flash]").forEach(el => {
    setTimeout(() => el.remove(), 4000)
  })
})
