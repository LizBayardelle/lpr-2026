import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import Link from "@tiptap/extension-link"
import Image from "@tiptap/extension-image"
import Underline from "@tiptap/extension-underline"
import TextAlign from "@tiptap/extension-text-align"
import Placeholder from "@tiptap/extension-placeholder"

function icon(name) {
  return `<i class="fa-solid fa-${name}"></i>`
}

function createHeadingDropdown(editor) {
  const wrapper = document.createElement("div")
  wrapper.className = "wysiwyg-dropdown"

  const toggle = document.createElement("button")
  toggle.type = "button"
  toggle.className = "wysiwyg-dropdown-toggle"
  toggle.innerHTML = `<span class="wysiwyg-dropdown-label">Paragraph</span> ${icon("chevron-down")}`
  toggle.title = "Text style"

  const menu = document.createElement("div")
  menu.className = "wysiwyg-dropdown-menu"

  const options = [
    { label: "Paragraph", command: () => editor.chain().focus().setParagraph().run(), check: () => editor.isActive("paragraph") && !editor.isActive("heading") },
{ label: "Heading 2", tag: "h2", command: () => editor.chain().focus().toggleHeading({ level: 2 }).run(), check: () => editor.isActive("heading", { level: 2 }) },
    { label: "Heading 3", tag: "h3", command: () => editor.chain().focus().toggleHeading({ level: 3 }).run(), check: () => editor.isActive("heading", { level: 3 }) },
    { label: "Heading 4", tag: "h4", command: () => editor.chain().focus().toggleHeading({ level: 4 }).run(), check: () => editor.isActive("heading", { level: 4 }) },
    { label: "Heading 5", tag: "h5", command: () => editor.chain().focus().toggleHeading({ level: 5 }).run(), check: () => editor.isActive("heading", { level: 5 }) },
    { label: "Heading 6", tag: "h6", command: () => editor.chain().focus().toggleHeading({ level: 6 }).run(), check: () => editor.isActive("heading", { level: 6 }) },
  ]

  options.forEach(opt => {
    const item = document.createElement("button")
    item.type = "button"
    item.className = "wysiwyg-dropdown-item"
    if (opt.tag) {
      item.innerHTML = `<${opt.tag} style="margin:0">${opt.label}</${opt.tag}>`
    } else {
      item.textContent = opt.label
    }
    item.addEventListener("click", (e) => {
      e.preventDefault()
      opt.command()
      menu.classList.remove("is-open")
    })
    item._check = opt.check
    item._label = opt.label
    menu.appendChild(item)
  })

  toggle.addEventListener("click", (e) => {
    e.preventDefault()
    e.stopPropagation()
    menu.classList.toggle("is-open")
  })

  // Close dropdown when clicking outside
  document.addEventListener("click", () => menu.classList.remove("is-open"))

  wrapper.appendChild(toggle)
  wrapper.appendChild(menu)

  // Store references for updating active state
  wrapper._toggle = toggle
  wrapper._menu = menu
  wrapper._options = options

  return wrapper
}

function updateHeadingDropdown(wrapper, editor) {
  const label = wrapper._toggle.querySelector(".wysiwyg-dropdown-label")
  const items = wrapper._menu.querySelectorAll(".wysiwyg-dropdown-item")
  let activeLabel = "Paragraph"

  items.forEach((item, i) => {
    const isActive = wrapper._options[i].check()
    item.classList.toggle("is-active", isActive)
    if (isActive) activeLabel = wrapper._options[i].label
  })

  label.textContent = activeLabel
}

function createToolbar(editor) {
  const toolbar = document.createElement("div")
  toolbar.className = "wysiwyg-toolbar"

  // Heading dropdown
  const headingDropdown = createHeadingDropdown(editor)
  toolbar.appendChild(headingDropdown)

  const sep0 = document.createElement("span")
  sep0.className = "wysiwyg-separator"
  toolbar.appendChild(sep0)

  const groups = [
    [
      { icon: "bold", command: () => editor.chain().focus().toggleBold().run(), active: "bold", title: "Bold" },
      { icon: "italic", command: () => editor.chain().focus().toggleItalic().run(), active: "italic", title: "Italic" },
      { icon: "underline", command: () => editor.chain().focus().toggleUnderline().run(), active: "underline", title: "Underline" },
      { icon: "strikethrough", command: () => editor.chain().focus().toggleStrike().run(), active: "strike", title: "Strikethrough" },
    ],
    [
      { icon: "list-ul", command: () => editor.chain().focus().toggleBulletList().run(), active: "bulletList", title: "Bullet List" },
      { icon: "list-ol", command: () => editor.chain().focus().toggleOrderedList().run(), active: "orderedList", title: "Ordered List" },
      { icon: "quote-left", command: () => editor.chain().focus().toggleBlockquote().run(), active: "blockquote", title: "Blockquote" },
    ],
    [
      { icon: "align-left", command: () => editor.chain().focus().setTextAlign("left").run(), active: () => editor.isActive({ textAlign: "left" }), title: "Align Left" },
      { icon: "align-center", command: () => editor.chain().focus().setTextAlign("center").run(), active: () => editor.isActive({ textAlign: "center" }), title: "Align Center" },
      { icon: "align-right", command: () => editor.chain().focus().setTextAlign("right").run(), active: () => editor.isActive({ textAlign: "right" }), title: "Align Right" },
    ],
    [
      { icon: "link", command: () => {
        if (editor.isActive("link")) {
          editor.chain().focus().unsetLink().run()
        } else {
          const url = prompt("Enter URL:")
          if (url) editor.chain().focus().extendMarkRange("link").setLink({ href: url }).run()
        }
      }, active: "link", title: "Link" },
      { icon: "image", command: () => {
        const url = prompt("Enter image URL:")
        if (url) editor.chain().focus().setImage({ src: url }).run()
      }, title: "Image" },
    ],
    [
      { icon: "code", command: () => editor.chain().focus().toggleCodeBlock().run(), active: "codeBlock", title: "Code Block" },
      { icon: "minus", command: () => editor.chain().focus().setHorizontalRule().run(), title: "Horizontal Rule" },
    ],
    [
      { icon: "rotate-left", command: () => editor.chain().focus().undo().run(), title: "Undo" },
      { icon: "rotate-right", command: () => editor.chain().focus().redo().run(), title: "Redo" },
    ],
  ]

  groups.forEach((group, i) => {
    if (i > 0) {
      const sep = document.createElement("span")
      sep.className = "wysiwyg-separator"
      toolbar.appendChild(sep)
    }
    group.forEach(btn => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "wysiwyg-btn"
      button.innerHTML = icon(btn.icon)
      button.title = btn.title
      button.addEventListener("click", (e) => {
        e.preventDefault()
        btn.command()
      })
      button.dataset.active = typeof btn.active === "string" ? btn.active : ""
      if (typeof btn.active === "function") {
        button._activeFn = btn.active
      }
      toolbar.appendChild(button)
    })
  })

  // Update active states
  const onUpdate = () => {
    updateActive(toolbar, editor)
    updateHeadingDropdown(headingDropdown, editor)
  }
  editor.on("selectionUpdate", onUpdate)
  editor.on("update", onUpdate)

  return toolbar
}

function updateActive(toolbar, editor) {
  toolbar.querySelectorAll(".wysiwyg-btn").forEach(btn => {
    const activeName = btn.dataset.active
    let isActive = false
    if (activeName) {
      isActive = editor.isActive(activeName)
    } else if (btn._activeFn) {
      isActive = btn._activeFn()
    }
    btn.classList.toggle("is-active", isActive)
  })
}

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-wysiwyg]").forEach(textarea => {
    // Hide the original textarea
    textarea.style.display = "none"

    // Create wrapper
    const wrapper = document.createElement("div")
    wrapper.className = "wysiwyg-wrapper"
    textarea.parentNode.insertBefore(wrapper, textarea)

    // Create editor element
    const editorEl = document.createElement("div")
    editorEl.className = "wysiwyg-editor"

    const editor = new Editor({
      element: editorEl,
      extensions: [
        StarterKit,
        Underline,
        Link.configure({ openOnClick: false, HTMLAttributes: { target: "_blank" } }),
        Image,
        TextAlign.configure({ types: ["heading", "paragraph"] }),
        Placeholder.configure({ placeholder: "Write your article…" }),
      ],
      content: textarea.value || "",
      onUpdate: ({ editor }) => {
        textarea.value = editor.getHTML()
      },
    })

    const toolbar = createToolbar(editor)
    wrapper.appendChild(toolbar)
    wrapper.appendChild(editorEl)
  })
})
