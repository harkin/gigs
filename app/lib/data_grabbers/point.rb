module DataGrabbers
  # This is for the 3 Arena, used to be called the Point ages ago and class names can't start with a number so...
  class Point

    EVENTS_URL = "https://3arena.ie/search/events/P0/?sort=upcoming&type=all"

    def self.get_events
      start_time = Time.now.to_i

      response = Faraday.get(EVENTS_URL)
      raw_events = JSON.parse(response.body)
      next_url = raw_events["pagination"].first["pages"]["next"]

      loop do
        break if next_url.blank?
        response = Faraday.get(next_url)
        more_events = JSON.parse(response.body)
        next_url = more_events["pagination"].first["pages"]["next"]
        raw_events["results"] += more_events["results"]
      end

      events = []
      raw_events["results"].each do |event|
        event["showDates"].each do |date|
          events.push(
            {
              title: event["heading"].strip,
              event_date: Time.parse(date["showDate"]),
              ticket_status: normalise_ticket_status(date["status"]),
              link_to_buy_ticket: event["ticketUrl"],
              venue: :point,
              more_info: event["showUrl"],
            }
          )
        end
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :point).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} The Point events in #{Time.now.to_i - start_time} seconds"

      events
    end

    private_class_method def self.normalise_ticket_status(status)
      case status
      when "Normal"
        :available
      when "Limited Availability"
        :limited_availability
      when "Sold Out"
        :sold_out
      else
        :unknown
      end
    end

  end
end