module ApplicationHelper
  def btn_tag(label, href = nil, **opts)
    css = ["btn", opts.delete(:class)].compact.join(" ")
    corners = content_tag(:span, "", class: "corners-t") + content_tag(:span, "", class: "corners-b")

    if href
      link_to(corners + label, href, class: css, **opts)
    else
      content_tag(:button, corners + label, class: css, **opts)
    end
  end

  def btn_filled_tag(label, href = nil, variant: "primary", **opts)
    css = ["btn-filled", "btn-filled-#{variant}", opts.delete(:class)].compact.join(" ")

    if href
      link_to(label, href, class: css, **opts)
    else
      content_tag(:button, label, class: css, **opts)
    end
  end
end
