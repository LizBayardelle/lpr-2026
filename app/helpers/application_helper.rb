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

  # Options for a "pertains to month" select on a loan. Spans from the loan's
  # origination month through two months ahead of today. Each option's value is
  # the first day of the month (e.g. "2026-04-01"), label like "April 2026".
  def pertains_to_month_options(loan)
    first = loan.origination_date.beginning_of_month
    last = Date.current.beginning_of_month >> 2
    last = first if last < first

    months = []
    cursor = first
    while cursor <= last
      months << [cursor.strftime("%B %Y"), cursor.to_s]
      cursor = cursor >> 1
    end
    months.reverse
  end
end
