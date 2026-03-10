document.addEventListener("DOMContentLoaded", () => {
  const nav = document.getElementById("main-nav")
  const userBtn = document.getElementById("user-menu-btn")
  const userWrap = userBtn?.closest(".main-nav-user")
  const hamburgerBtn = document.getElementById("hamburger-btn")
  const navLinks = document.getElementById("nav-links")

  // scroll: transparent -> solid
  if (nav) {
    const onScroll = () => {
      nav.classList.toggle("scrolled", window.scrollY > 40)
    }
    window.addEventListener("scroll", onScroll, { passive: true })
    onScroll()
  }

  // user dropdown toggle
  if (userBtn && userWrap) {
    userBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      userWrap.classList.toggle("open")
    })

    document.addEventListener("click", (e) => {
      if (!userWrap.contains(e.target)) {
        userWrap.classList.remove("open")
      }
    })

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        userWrap.classList.remove("open")
      }
    })
  }

  // hamburger toggle
  if (hamburgerBtn && navLinks) {
    hamburgerBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      const isOpen = nav.classList.toggle("mobile-open")
      hamburgerBtn.setAttribute("aria-expanded", isOpen)
    })

    // close mobile menu on link click
    navLinks.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => {
        nav.classList.remove("mobile-open")
        hamburgerBtn.setAttribute("aria-expanded", "false")
      })
    })

    // close on escape
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && nav.classList.contains("mobile-open")) {
        nav.classList.remove("mobile-open")
        hamburgerBtn.setAttribute("aria-expanded", "false")
      }
    })
  }
})
