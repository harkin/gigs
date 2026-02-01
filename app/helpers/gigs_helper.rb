module GigsHelper
  def status_class_for(event)
    case event.ticket_status
    when "available" then "status-available"
    when "limited_availability" then "status-limited"
    when "sold_out" then "status-sold-out"
    else "status-unknown"
    end
  end

  def venue_color_for(venue)
    case venue
    when "academy" then "#6366f1"
    when "button_factory" then "#ec4899"
    when "point" then "#f59e0b"
    when "olympia" then "#10b981"
    when "vicar_street" then "#8b5cf6"
    when "whelans" then "#ef4444"
    else "#6b7280"
    end
  end
end
