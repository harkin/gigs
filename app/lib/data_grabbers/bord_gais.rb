module DataGrabbers
  class BordGais

    EVENTS_URL = "https://www.bordgaisenergytheatre.ie/shows-listing/"

    def self.get_events
      start_time = Time.now.to_i

      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)

      events = document.css("div.show-listing__item").map do |card|
        details = card.css("p.show-item__details span").map { |span| span.text.strip }
        buy_button = card.css("a.show-item__button").find { |button| button.text.strip.match?(/buy|on sale/i) }
        event_date, end_date = parse_event_dates(details.find { |text| !text.include?("€") })

        {
          title: card.at_css("h4.show-item__title").text.strip,
          event_date: event_date,
          end_date: end_date,
          price: details.find { |text| text.include?("€") }&.sub(/\ATickets\s+/i, ""),
          ticket_status: buy_button ? :available : :unknown,
          link_to_buy_ticket: buy_button&.attribute("href")&.value,
          more_info: card.at_css("h4.show-item__title a")&.attribute("href")&.value,
          venue: :bord_gais,
        }
      end

      EventValidator.validate!(events, venue: :bord_gais)

      ActiveRecord::Base.transaction do
        Event.where(venue: :bord_gais).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Bord Gáis events in #{Time.now.to_i - start_time} seconds"

      events
    end

    # Listings show a run as "19 June - 05 July 2026" (or a single "02 August
    # 2026"). Return [start, end], with end nil for a single date. The start
    # borrows the month/year from the end where it omits them, and steps back a
    # year for runs that cross New Year.
    private_class_method def self.parse_event_dates(text)
      start_part, end_part = text.split(/\s+[-–]\s+/, 2)
      return [Date.parse(start_part), nil] unless end_part

      end_date = Date.parse(end_part)
      start_part += " #{end_date.strftime("%B")}" unless start_part.match?(/[A-Za-z]/)
      start_part += " #{end_date.year}" unless start_part.match?(/\d{4}/)
      start_date = Date.parse(start_part)
      start_date > end_date ? [start_date.prev_year, end_date] : [start_date, end_date]
    end

  end
end
