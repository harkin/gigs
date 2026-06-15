module DataGrabbers
  class NationalConcertHall

    BASE_URL = "https://www.nch.ie"
    EVENTS_URL = "#{BASE_URL}/all-events-listing/"
    TIME_ZONE = ActiveSupport::TimeZone["Europe/Dublin"]
    # Pages past the end clamp to the last page, so stop once one repeats.
    MAX_PAGES = 40

    def self.get_events
      start_time = Time.now.to_i

      events = []
      seen = Set.new

      (1..MAX_PAGES).each do |page|
        cards = Nokogiri::HTML(Faraday.get(EVENTS_URL, page: page).body).css("div.feature-card")
        new_events = cards.filter_map { |card| parse_card(card) }.reject { |event| seen.include?(event[:more_info]) }
        break if new_events.empty?

        new_events.each { |event| seen.add(event[:more_info]) }
        events.concat(new_events)
      end

      EventValidator.validate!(events, venue: :national_concert_hall)

      ActiveRecord::Base.transaction do
        Event.where(venue: :national_concert_hall).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} National Concert Hall events in #{Time.now.to_i - start_time} seconds"

      events
    end

    # Each card carries two <p class="meta"> lines (category then date); the date
    # one holds the year. Sold-out cards swap the buy button for a "Sold Out" note.
    def self.parse_card(card)
      date_text = card.css("p.meta").map { |meta| meta.text.strip }.find { |text| text.match?(/\d{4}/) }
      return unless date_text

      detail_path = card.css("a").filter_map { |link| link["href"] }.find { |href| href.start_with?("/all-events-listing/") }

      {
        title: card.at_css("h2.title").text.strip,
        event_date: TIME_ZONE.parse(date_text),
        price: nil,
        ticket_status: card.at_css("p.msg-main") ? :sold_out : :available,
        link_to_buy_ticket: card.at_css("a.btn-main")&.attribute("href")&.value,
        more_info: "#{BASE_URL}#{detail_path}",
        venue: :national_concert_hall,
      }
    end

  end
end
