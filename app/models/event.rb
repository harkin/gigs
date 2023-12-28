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
end