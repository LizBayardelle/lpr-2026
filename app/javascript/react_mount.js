import React from "react"
import { createRoot } from "react-dom/client"
import components from "./components"

document.addEventListener("DOMContentLoaded", () => {
  const nodes = document.querySelectorAll("[data-react-component]")

  nodes.forEach((node) => {
    const name = node.dataset.reactComponent
    const props = JSON.parse(node.dataset.reactProps || "{}")
    const Component = components[name]

    if (Component) {
      const root = createRoot(node)
      root.render(React.createElement(Component, props))
    } else {
      console.warn(`React component "${name}" not found. Did you register it in components/index.js?`)
    }
  })
})
