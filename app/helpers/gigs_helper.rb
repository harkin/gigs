module GigsHelper
  THEMES = %w[light dark festival aurora].freeze

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
