module DataGrabbers
  class Fidelity

    EVENTS_URL = "https://www.fidelitybar.ie/whats-on"

    def self.get_events
      start_time = Time.now.to_i

      document = Nokogiri::HTML(Faraday.get(EVENTS_URL).body)

      # Dated shows are <h1>FRIDAY 26 JUNE</h1><p>Antal [<a>Tickets</a>]</p> pairs.
      # The "This Week" headings are bare day names with no number, so they fall
      # out of the date match. No year is shown, so carry a running year and roll
      # it forward when the month steps back.
      year = Date.current.year
      previous_month = Date.current.month

      events = document.css("div.sqs-html-content h1").filter_map do |heading|
        match = heading.text.match(/(\d{1,2})\s+([A-Za-z]+)/)
        next unless match

        month = Date::MONTHNAMES.index(match[2].capitalize)
        next unless month

        year += 1 if month < previous_month
        previous_month = month

        para = heading.next_element
        link = para&.name == "p" ? para.at_css("a")&.attribute("href")&.value : nil
        next unless link&.include?("eventbrite")

        title = para.text.split("[").first.strip
        next if title.blank? || title.casecmp?("TBA")

        {
          title: title,
          event_date: Date.new(year, month, match[1].to_i),
          price: nil,
          ticket_status: :available,
          link_to_buy_ticket: link,
          more_info: link,
          venue: :fidelity,
        }
      end

      EventValidator.validate!(events, venue: :fidelity)

      ActiveRecord::Base.transaction do
        Event.where(venue: :fidelity).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Fidelity events in #{Time.now.to_i - start_time} seconds"

      events
    end

  end
end
