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
        start_md, end_md = month_day_range(card.at_css("p.event-date").text)
        month, day = start_md
        year += 1 if month < previous_month
        previous_month = month

        # A run's end can roll into the next year (e.g. Dec - Jan).
        end_date = nil
        if end_md
          end_month, end_day = end_md
          end_year = end_month < month ? year + 1 : year
          end_date = Date.new(end_year, end_month, end_day)
        end

        buy_button = card.at_css("a.btn-primary")

        {
          title: card.at_css("h3.event-title").text.strip,
          event_date: Date.new(year, month, day),
          end_date: end_date,
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

    # Dates read like "17th Jun. - 6th Sep." (a run) or "17th Jun." (one night).
    # Return [[start_month, start_day], [end_month, end_day] or nil]. Years are
    # resolved by the caller from listing order.
    def self.month_day_range(text)
      start_part, end_part = text.split(/\s[-–]\s/, 2).map(&:strip)
      [month_day(start_part), end_part && month_day(end_part)]
    end

    def self.month_day(text)
      day = text[/\d{1,2}/].to_i
      month = Date::ABBR_MONTHNAMES.index(text[/[A-Za-z]{3,}/]&.capitalize)
      [month, day]
    end

  end
end
