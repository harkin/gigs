class Event < ApplicationRecord
  enum :venue, {
    academy: 0,
    # bord_gais:,
    button_factory: 4,
    # grand_social:,
    # national_concert_hall:,
    # pavilion:,
    # pepper_canister:,
    point: 1,
    olympia: 2,
    # opium:,
    # sugar_club:
    vicar_street: 5,
    whelans: 3,
  }

  enum :ticket_status, {
    available: 0,
    limited_availability: 1,
    sold_out: 2,
    unknown: 3,
  }

  def renderable_venue
    case venue
    when "academy"
      "The Academy"
    when "button_factory"
      "Button Factory"
    when "point"
      "The 3Arena"
    when "olympia"
      "The Olympia"
    when "vicar_street"
      "Vicar Street"
    when "whelans"
      "Whelans"
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
