module DataGrabbers
  class ButtonFactory

    EVENTS_URL = "https://buttonfactory.ie/shows"
    EVENTS_URI = URI.parse(EVENTS_URL)

    def self.get_events
      Store.replace(:button_factory) do
        events = []

        response = Faraday.get(EVENTS_URL)
        document = Nokogiri::HTML(response.body)
        gigs = document.css("div.eventlist--upcoming").css("article.eventlist-event")

        gigs.each do |gig|
          title = gig.css("h1.eventlist-title").text.strip

          # The <time> datetime attribute is the machine-readable ISO date; the
          # page exposes no reliable start time, so events are date-only.
          event_date = Date.parse(gig.css("time.event-date").attribute("datetime").value)

          # The "upcoming" section still lists a few just-passed shows.
          next if event_date < Date.current

          more_info_relative_link = gig.css("a.eventlist-button").attribute("href").value
          more_info_uri = URI.parse(more_info_relative_link)
          more_info_uri.scheme = EVENTS_URI.scheme
          more_info_uri.host = EVENTS_URI.host

          events.push(
            {
              title: title,
              event_date: event_date,
              ticket_status: :unknown, # shows page carries no ticket info
              link_to_buy_ticket: nil,
              more_info: more_info_uri.to_s,
              venue: :button_factory,
            }
          )
        end

        events
      end
    end

  end
end