module DataGrabbers
  class GrandSocial

    EVENTS_APP_ID = "140603ad-af8d-84a5-2c80-a0f60cb47351"
    TOKENS_URL = "https://www.thegrandsocial.ie/_api/v1/access-tokens"
    EVENTS_API_URL = "https://www.thegrandsocial.ie/_api/wix-events-web/v1/events"
    EVENT_PAGE_URL = "https://www.thegrandsocial.ie/events/"

    def self.get_events
      start_time = Time.now.to_i

      instance = fetch_instance

      events = fetch_upcoming_events(instance).map do |event|
        config = event.dig("scheduling", "config")
        {
          title: event["title"].strip,
          event_date: Time.parse(config["startDate"]).in_time_zone(config["timeZoneId"]),
          price: nil,
          ticket_status: :unknown,
          link_to_buy_ticket: nil,
          more_info: "#{EVENT_PAGE_URL}#{event["slug"]}",
          venue: :grand_social,
        }
      end.sort_by { |event| event[:event_date] }

      EventValidator.validate!(events, venue: :grand_social)

      ActiveRecord::Base.transaction do
        Event.where(venue: :grand_social).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Grand Social events in #{Time.now.to_i - start_time} seconds"

      events
    end

    # The listing runs on the Wix Events app, whose query API needs a signed
    # instance token. Wix issues one for the app on this endpoint.
    def self.fetch_instance
      tokens = JSON.parse(Faraday.get(TOKENS_URL).body)
      tokens.dig("apps", EVENTS_APP_ID, "instance").presence ||
        raise("Grand Social: no events app instance token")
    end

    # The API returns every event ever, so filter to scheduled future shows. It
    # ignores sort params, so order by date after collecting all pages.
    def self.fetch_upcoming_events(instance)
      from = Time.current.utc.iso8601
      events = []

      loop do
        response = Faraday.get(EVENTS_API_URL, {
          fieldset: "FULL",
          status: "SCHEDULED",
          startDateFrom: from,
          limit: 100,
          offset: events.size,
        }) { |request| request.headers["Authorization"] = instance }

        body = JSON.parse(response.body)
        raise "Grand Social: unexpected events API response" unless body["events"].is_a?(Array)

        events.concat(body["events"])
        break if body["events"].empty? || events.size >= body["total"].to_i
      end

      events
    end

  end
end
