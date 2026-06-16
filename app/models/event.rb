class Event < ApplicationRecord
  enum :venue, {
    academy: 0,
    bord_gais: 7,
    button_factory: 4,
    gaiety: 11,
    grand_social: 8,
    national_concert_hall: 10,
    # pavilion:,
    # pepper_canister:,
    point: 1,
    olympia: 2,
    # opium:,
    oreilly_theatre: 6,
    # sugar_club:
    vicar_street: 5,
    whelans: 3,
    workmans: 9,
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
    when "bord_gais"
      "Bord Gáis Energy Theatre"
    when "button_factory"
      "Button Factory"
    when "gaiety"
      "The Gaiety"
    when "grand_social"
      "The Grand Social"
    when "national_concert_hall"
      "National Concert Hall"
    when "point"
      "The 3Arena"
    when "olympia"
      "The Olympia"
    when "oreilly_theatre"
      "O'Reilly Theatre"
    when "vicar_street"
      "Vicar Street"
    when "whelans"
      "Whelans"
    when "workmans"
      "The Workman's Club"
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
