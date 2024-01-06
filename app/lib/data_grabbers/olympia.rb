module DataGrabbers
  class Olympia

    EVENTS_URL = "https://www.3olympia.ie/search/events/P%d?announced=&category=0"

    def self.get_events
      start_time = Time.now.to_i

      response = Faraday.get(EVENTS_URL % 0)
      raw_events = JSON.parse(response.body)
      number_of_events = raw_events["numberOfHits"]
      how_many_more_searches_to_do = (number_of_events / 24.0).ceil
      how_many_more_searches_to_do.times do |index|
        response = Faraday.get(EVENTS_URL % ((index + 1) * 24))
        more_events = JSON.parse(response.body)
        raw_events["results"] += more_events["results"]
      end

      events = []
      raw_events["results"].each do |event|
        # TODO the olympia sometimes includes a sparse range of dates in the response
        # A number of events aren't being listed right now, only the first night

        ticket_url = event["url"]["tickets"].eql?("#!") ? nil : event["url"]["tickets"]
        events.push(
          {
            title: event["title"].strip,
            event_date: Time.parse("#{event["time"]} #{event["date"]["single"]}"),
            ticket_status: normalise_ticket_status(event["status"]["message"]),
            link_to_buy_ticket: ticket_url,
            venue: :olympia,
            more_info: event["url"]["event"],
            price: event["originalPrice"],
          }
        )
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :olympia).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} The Olympia events in #{Time.now.to_i - start_time} seconds"

      raw_events
    end

    private_class_method def self.normalise_ticket_status(status)
      case status
      when "Tickets Available"
        :available
      when "Low Availability", "Last Seats"
        :limited_availability
      when "Sold Out"
        :sold_out
      else
        :unknown
      end
    end

  end
end