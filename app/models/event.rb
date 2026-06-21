class Event < ApplicationRecord
  enum :venue, {
    academy: 0,
    aviva_stadium: 16,
    bord_gais: 7,
    button_factory: 4,
    croke_park: 15,
    gaiety: 11,
    grand_social: 8,
    helix: 13,
    iveagh_gardens: 20,
    malahide_castle: 21,
    marlay_park: 17,
    national_concert_hall: 10,
    national_stadium: 14,
    pavilion: 12,
    # pepper_canister:,
    point: 1,
    olympia: 2,
    # opium:,
    oreilly_theatre: 6,
    royal_hospital_kilmainham: 19,
    st_annes_park: 18,
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
    when "aviva_stadium"
      "Aviva Stadium"
    when "bord_gais"
      "Bord Gáis Energy Theatre"
    when "button_factory"
      "Button Factory"
    when "croke_park"
      "Croke Park"
    when "gaiety"
      "The Gaiety"
    when "grand_social"
      "The Grand Social"
    when "helix"
      "The Helix"
    when "iveagh_gardens"
      "Iveagh Gardens"
    when "malahide_castle"
      "Malahide Castle"
    when "marlay_park"
      "Marlay Park"
    when "national_concert_hall"
      "National Concert Hall"
    when "national_stadium"
      "The National Stadium"
    when "point"
      "The 3Arena"
    when "olympia"
      "The Olympia"
    when "pavilion"
      "Pavilion Theatre"
    when "oreilly_theatre"
      "O'Reilly Theatre"
    when "royal_hospital_kilmainham"
      "Royal Hospital Kilmainham"
    when "st_annes_park"
      "St Anne's Park"
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
