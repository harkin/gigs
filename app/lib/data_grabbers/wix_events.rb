module DataGrabbers
  # Shared grabber for venues running the Wix Events app. Its query API needs a
  # short-lived signed instance token, issued per site on the access-tokens
  # endpoint. The feed carries no ticket/price fields, so status is unknown.
  module WixEvents
    module_function

    APP_ID = "140603ad-af8d-84a5-2c80-a0f60cb47351"

    def get_events(host:, venue:, events_path: "/events/")
      start_time = Time.now.to_i

      instance = fetch_instance(host)

      events = fetch_upcoming(host, instance).map do |event|
        config = event.dig("scheduling", "config")
        {
          title: TitleCleaner.strip_promoter(event["title"].strip),
          event_date: Time.parse(config["startDate"]).in_time_zone(config["timeZoneId"]),
          price: nil,
          ticket_status: :unknown,
          link_to_buy_ticket: nil,
          more_info: "https://#{host}#{events_path}#{event["slug"]}",
          venue: venue,
        }
      end.sort_by { |event| event[:event_date] }

      EventValidator.validate!(events, venue: venue)

      ActiveRecord::Base.transaction do
        Event.where(venue: venue).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} #{venue} events in #{Time.now.to_i - start_time} seconds"

      events
    end

    def fetch_instance(host)
      tokens = JSON.parse(Faraday.get("https://#{host}/_api/v1/access-tokens").body)
      tokens.dig("apps", APP_ID, "instance").presence ||
        raise("#{host}: no Wix Events instance token")
    end

    # The API returns every event ever, so filter to scheduled future shows. It
    # ignores sort params, so order by date after collecting all pages.
    def fetch_upcoming(host, instance)
      url = "https://#{host}/_api/wix-events-web/v1/events"
      from = Time.current.utc.iso8601
      events = []

      loop do
        response = Faraday.get(url, {
          fieldset: "FULL",
          status: "SCHEDULED",
          startDateFrom: from,
          limit: 100,
          offset: events.size,
        }) { |request| request.headers["Authorization"] = instance }

        body = JSON.parse(response.body)
        raise "#{host}: unexpected Wix Events response" unless body["events"].is_a?(Array)

        events.concat(body["events"])
        break if body["events"].empty? || events.size >= body["total"].to_i
      end

      events
    end
  end
end
