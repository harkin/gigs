module DataGrabbers
  class Gaiety

    EVENTS_URL = "https://www.gaietytheatre.ie/events/"

    def self.get_events
      start_time = Time.now.to_i

      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)

      # Cards list a run's start; no year is shown, so carry a running year and
      # roll it forward when the month steps back (a run starting after New Year).
      year = Date.current.year
      previous_month = Date.current.month

      events = document.css("div.event-container").map do |card|
        month, day = start_month_day(card.at_css("p.event-date").text)
        year += 1 if month < previous_month
        previous_month = month

        buy_button = card.at_css("a.btn-primary")

        {
          title: card.at_css("h3.event-title").text.strip,
          event_date: Date.new(year, month, day),
          price: nil,
          ticket_status: buy_button ? :available : :unknown,
          link_to_buy_ticket: buy_button&.attribute("href")&.value,
          more_info: card.at_css(".event-poster a")&.attribute("href")&.value,
          venue: :gaiety,
        }
      end

      EventValidator.validate!(events, venue: :gaiety)

      ActiveRecord::Base.transaction do
        Event.where(venue: :gaiety).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Gaiety events in #{Time.now.to_i - start_time} seconds"

      events
    end

    # Dates read like "17th Jun. - 6th Sep."; take the start and return its
    # [month, day]. Year is resolved by the caller from listing order.
    def self.start_month_day(text)
      start = text.split(/\s[-–]\s/).first.strip
      day = start[/\d{1,2}/].to_i
      month = Date::ABBR_MONTHNAMES.index(start[/[A-Za-z]{3,}/]&.capitalize)
      [month, day]
    end

  end
end
