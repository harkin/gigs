module DataGrabbers
  # This is for the 3 Arena, used to be called the Point ages ago and class names can't start with a number so...
  class Point

    EVENTS_URL = "https://3arena.ie/search/events/P0/?sort=upcoming&type=all"

    def self.get_events
      response = Faraday.get(EVENTS_URL)
      events = JSON.parse(response.body)
      next_url = events["pagination"].first["pages"]["next"]

      loop do
        break if next_url.blank?
        response = Faraday.get(next_url)
        more_events = JSON.parse(response.body)
        next_url = more_events["pagination"].first["pages"]["next"]
        events["results"] += more_events["results"]
      end

      events
    end
  end
end