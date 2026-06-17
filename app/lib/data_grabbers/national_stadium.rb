module DataGrabbers
  class NationalStadium

    EVENTS_URL = "https://www.thenationalstadium.ie/"

    # The site lists gigs as Ticketmaster links whose slug carries the title and
    # date, e.g. ".../loyle-carner-29-08-2026/event/...". Parse those; anything
    # without a trailing date is skipped (EventValidator guards a bad scrape).
    TICKET_LINK = %r{https?://www\.ticketmaster\.ie/[a-z0-9-]+/event/[A-Z0-9]+}
    SLUG_DATE = %r{/([a-z0-9-]+?)-(?:dublin-)?(\d{2})-(\d{2})-(\d{4})/event/}

    def self.get_events
      start_time = Time.now.to_i

      body = Faraday.get(EVENTS_URL).body

      events = body.scan(TICKET_LINK).uniq.filter_map do |url|
        match = url.match(SLUG_DATE)
        next unless match

        {
          title: match[1].tr("-", " ").split.map(&:capitalize).join(" "),
          event_date: Date.new(match[4].to_i, match[3].to_i, match[2].to_i),
          price: nil,
          ticket_status: :available,
          link_to_buy_ticket: url,
          more_info: nil,
          venue: :national_stadium,
        }
      end.sort_by { |event| event[:event_date] }

      EventValidator.validate!(events, venue: :national_stadium)

      ActiveRecord::Base.transaction do
        Event.where(venue: :national_stadium).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} National Stadium events in #{Time.now.to_i - start_time} seconds"

      events
    end

  end
end
