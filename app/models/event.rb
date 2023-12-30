class Event < ApplicationRecord
  enum venue: {
    academy: 0,
    point: 1,
    olympia: 2,
  }

  enum ticket_status: {
    available: 0,
    limited_availability: 1,
    sold_out: 2,
    unknown: 3,
  }

  def renderable_venue
    case venue
    when "academy"
      "The Academy"
    when "point"
      "The 3Arena"
    when "olympia"
      "The Olympia"
    end
  end

  def renderable_ticket_status
    case ticket_status
    when "available"
      return  "Available"
    when "limited_availability"
      "Limited Availability"
    when "sold_out"
      "Sold Out"
    when "unknown"
      "Unknown"
    end
  end
end