module DataGrabbers
  class Workmans

    EVENTS_URL = "https://theworkmansclub.com/events/"
    TIME_ZONE = ActiveSupport::TimeZone["Europe/Dublin"]

    def self.get_events
      start_time = Time.now.to_i

      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)

      # The listing is ordered ascending with no year, so carry a running year
      # and roll it forward when the month steps back (December into January).
      year = Date.current.year
      previous_month = Date.current.month

      events = document.css("div.list_entry").map do |entry|
        month = Date::ABBR_MONTHNAMES.index(entry.at_css(".month").text.strip)
        year += 1 if month < previous_month
        previous_month = month
        day = entry.at_css(".day").text.strip.to_i

        price_text = entry.at_css(".ticket_price")&.text&.strip
        sold_out = price_text.to_s.match?(/sold\s*out/i)

        {
          title: TitleCleaner.strip_promoter(entry.at_css(".thetitle").text.strip),
          event_date: event_date(Date.new(year, month, day), entry.at_css(".time")&.text),
          # The price slot also holds junk like "Buy"; keep only real amounts.
          price: price_text&.match?(/€|free/i) ? price_text : nil,
          ticket_status: sold_out ? :sold_out : :available,
          link_to_buy_ticket: entry.at_css(".ticket_link a")&.attribute("href")&.value,
          more_info: entry.css("a").find { |link| link["href"]&.include?("/events/") }&.attribute("href")&.value,
          venue: :workmans,
        }
      end

      EventValidator.validate!(events, venue: :workmans)

      ActiveRecord::Base.transaction do
        Event.where(venue: :workmans).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Workmans events in #{Time.now.to_i - start_time} seconds"

      events
    end

    # Times read like "10:30pm (First Floor)"; take the leading clock value and
    # anchor it to the date in Dublin time, falling back to the bare date.
    def self.event_date(date, time_text)
      clock = time_text.to_s[/\d{1,2}(:\d{2})?\s*[ap]m/i]
      clock ? TIME_ZONE.parse("#{date.iso8601} #{clock}") : date
    end

  end
end
