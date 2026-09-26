class Event < ApplicationRecord
  enum :venue, {
    academy: 0,
    aviva_stadium: 16,
    bord_gais: 7,
    button_factory: 4,
    croke_park: 15,
    fidelity: 22,
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

  VENUE_NAMES = {
    "academy" => "The Academy",
    "aviva_stadium" => "Aviva Stadium",
    "bord_gais" => "Bord Gáis Energy Theatre",
    "button_factory" => "Button Factory",
    "croke_park" => "Croke Park",
    "fidelity" => "Fidelity",
    "gaiety" => "The Gaiety",
    "grand_social" => "The Grand Social",
    "helix" => "The Helix",
    "iveagh_gardens" => "Iveagh Gardens",
    "malahide_castle" => "Malahide Castle",
    "marlay_park" => "Marlay Park",
    "national_concert_hall" => "National Concert Hall",
    "national_stadium" => "The National Stadium",
    "olympia" => "The Olympia",
    "oreilly_theatre" => "O'Reilly Theatre",
    "pavilion" => "Pavilion Theatre",
    "point" => "The 3Arena",
    "royal_hospital_kilmainham" => "Royal Hospital Kilmainham",
    "st_annes_park" => "St Anne's Park",
    "vicar_street" => "Vicar Street",
    "whelans" => "Whelans",
    "workmans" => "The Workman's Club",
  }.freeze

  enum :ticket_status, {
    available: 0,
    limited_availability: 1,
    sold_out: 2,
    unknown: 3,
  }

  # Production scrapes once a day, so this is the seven most recent refreshes.
  NEWLY_ANNOUNCED_WINDOW = 7.days

  scope :newly_announced, -> { where(first_seen_at: NEWLY_ANNOUNCED_WINDOW.ago..) }

  # Multi-day runs store the run's start in event_date and its last day in
  # end_date; single events leave end_date nil. An event counts as upcoming
  # until its last day passes, so an in-progress run stays visible.
  scope :upcoming, -> { where("COALESCE(end_date, event_date) >= ?", Date.current.beginning_of_day) }

  # "Wed, Jun 17 2026" for a single date, "17 Jun – 6 Sep 2026" for a run.
  def renderable_date
    return event_date.strftime("%a, %b %d %Y") unless multi_day?

    start_date = event_date.to_date
    finish_date = end_date.to_date
    start_format = start_date.year == finish_date.year ? "%-d %b" : "%-d %b %Y"
    "#{start_date.strftime(start_format)} – #{finish_date.strftime("%-d %b %Y")}"
  end

  def multi_day?
    end_date.present? && end_date.to_date != event_date.to_date
  end

  def renderable_venue
    VENUE_NAMES[venue]
  end

  def renderable_ticket_status
    ticket_status&.titleize
  end

  def newly_announced?
    first_seen_at.present? && first_seen_at > NEWLY_ANNOUNCED_WINDOW.ago
  end
end
