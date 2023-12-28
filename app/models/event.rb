class Event < ApplicationRecord
  enum venue: {
    academy: 0,
    point: 1,
    olympia: 2,
  }
end