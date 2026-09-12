module GigsHelper
  # The one source of truth for themes: the server validates ?theme= against
  # these keys, the switcher renders a swatch per entry, and the list is passed
  # to the browser on <html data-themes> so the JS agrees with both.
  THEMES = {
    "light" => { label: "Light", swatch: %w[#667eea #a855f7 #f093fb] },
    "dark" => { label: "Dark", swatch: %w[#818cf8 #6366f1 #1e293b] },
    "festival" => { label: "Festival", swatch: %w[#ff6b35 #ff4d8d #a64dff] },
    "aurora" => { label: "Aurora", swatch: %w[#5eead4 #8b5cf6 #ec4899] },
  }.freeze

  def status_class_for(event)
    case event.ticket_status
    when "available" then "status-available"
    when "limited_availability" then "status-limited"
    when "sold_out" then "status-sold-out"
    else "status-unknown"
    end
  end

  def status_color_for(event)
    case event.ticket_status
    when "available" then "#22c55e"
    when "limited_availability" then "#f59e0b"
    when "sold_out" then "#ef4444"
    else "#9ca3af"
    end
  end
end
