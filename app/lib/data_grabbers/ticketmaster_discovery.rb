module DataGrabbers
  # Shared grabber for promoter-driven venues with no usable listing site of
  # their own, sourced from the Ticketmaster Discovery API by venue id. The key
  # lives in Rails credentials as ticketmaster_api_key.
  module TicketmasterDiscovery
    module_function

    API_URL = "https://app.ticketmaster.com/discovery/v2/events.json"
    TIME_ZONE = "Europe/Dublin"
    # This is a music/comedy listing, so drop sports fixtures and the like.
    GIG_SEGMENTS = ["Music", "Arts & Theatre"].freeze

    def get_events(venue_id:, venue:)
      start_time = Time.now.to_i

      events = fetch_events(venue_id).filter_map { |event| build_event(event, venue) }

      # The Discovery API is authoritative and versioned, so a well-formed empty
      # result is a real off-season state for these seasonal venues, not scraper
      # drift — allow zero. fetch_events still raises on a malformed response.
      EventValidator.validate!(events, venue: venue, min_count: 0)

      ActiveRecord::Base.transaction do
        Event.where(venue: venue).delete_all
        Event.insert_all(events) if events.any?
      end

      puts "Finished grabbing #{events.count} #{venue} events in #{Time.now.to_i - start_time} seconds"

      events
    end

    def fetch_events(venue_id)
      key = Rails.application.credentials.ticketmaster_api_key
      raise "Ticketmaster: no ticketmaster_api_key in credentials" if key.blank?

      events = []
      page = 0

      loop do
        response = Faraday.get(API_URL, {
          apikey: key, venueId: venue_id, countryCode: "IE",
          size: 100, page: page, sort: "date,asc",
        })
        raise "Ticketmaster: HTTP #{response.status} for venue #{venue_id}" unless response.status == 200

        body = JSON.parse(response.body)
        raise "Ticketmaster: unexpected response for venue #{venue_id}" unless body.key?("page")

        events.concat(body.dig("_embedded", "events") || [])
        page += 1
        break if page >= body.dig("page", "totalPages").to_i
      end

      events
    end

    def build_event(event, venue)
      return unless GIG_SEGMENTS.include?(event.dig("classifications", 0, "segment", "name"))

      status = event.dig("dates", "status", "code")
      return if status == "cancelled"

      date = event_date(event.dig("dates", "start"))
      return unless date

      {
        title: event["name"].strip,
        event_date: date,
        price: price_range(event["priceRanges"]),
        ticket_status: status == "onsale" ? :available : :unknown,
        link_to_buy_ticket: event["url"],
        more_info: event["url"],
        venue: venue,
      }
    end

    def event_date(start)
      return unless start

      if start["dateTime"]
        Time.parse(start["dateTime"]).in_time_zone(TIME_ZONE)
      elsif start["localDate"]
        Date.parse(start["localDate"])
      end
    end

    def price_range(ranges)
      range = ranges&.find { |entry| entry["min"] }
      return unless range

      min, max = range["min"], range["max"]
      min == max ? format("€%g", min) : format("€%g–€%g", min, max)
    end
  end
end
