module DataGrabbers
  class Olympia

    EVENTS_URL = "https://www.3olympia.ie/search/events/P%d?announced=&category=0"

    def self.get_events
      response = Faraday.get(EVENTS_URL % 0)
      events = JSON.parse(response.body)
      number_of_events = events["numberOfHits"]
      how_many_more_searches_to_do = (number_of_events / 24.0).ceil
      how_many_more_searches_to_do.times do |index|
        response = Faraday.get(EVENTS_URL % ((index + 1) * 24))
        more_events = JSON.parse(response.body)
        events["results"] += more_events["results"]
      end
      events
    end
  end
end