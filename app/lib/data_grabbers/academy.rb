module DataGrabbers
  class Academy

    # The Academy's site is a Next.js app that fetches its event list from the
    # VenueCloud API (venueCloudId=21 is The Academy). We hit that JSON API
    # directly rather than scraping the rendered HTML -- it's the same data the
    # page hydrates from, and it doesn't break when they tweak their markup.
    # Covers all the venue's rooms (The Academy, The Academy 2, The Green Room,
    # ...), all tagged as :academy.
    EVENTS_URL = "https://www.venuecloud.net/api/events?venueCloudId=21"

    def self.get_events
      start_time = Time.now.to_i

      response = Faraday.get(EVENTS_URL)
      raw_events = JSON.parse(response.body)["events"] || []

      events = raw_events.map do |gig|
        {
          # subTitle (when present) is usually a support act, e.g. "+ Special
          # Guests: ...", so a plain space reads better than a dash.
          title: [gig["title"], gig["subTitle"]].compact_blank.join(" "),
          event_date: Time.parse(gig.dig("startDate", "date")),
          price: gig["pricing"],
          ticket_status: gig["isSoldOut"] ? :sold_out : :available,
          link_to_buy_ticket: gig["ticketsUrl"],
          # The Academy has no per-event page of its own; its Ticketmaster
          # listing is the only detail page, so it doubles as more_info.
          more_info: gig["ticketsUrl"],
          venue: :academy,
        }
      end

      EventValidator.validate!(events, venue: :academy)

      ActiveRecord::Base.transaction do
        Event.where(venue: :academy).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} The Academy events in #{Time.now.to_i - start_time} seconds"
      events
    end
  end
end
