module DataGrabbers
  # Shared grabber for venues on Ticketsolve, which exposes an identical
  # shows.xml feed per box office. One Event per show, anchored to its next
  # upcoming performance.
  module Ticketsolve
    module_function

    FEED_URL = "https://%s.ticketsolve.com/shows.xml"

    def get_events(subdomain:, venue:)
      start_time = Time.now.to_i

      feed = Nokogiri::XML(Faraday.get(format(FEED_URL, subdomain)).body)

      events = feed.xpath("//show").filter_map do |show|
        performances = upcoming_performances(show)
        next if performances.empty?

        next_up = performances.min_by { |performance| performance[:time] }
        {
          title: show.at_xpath("./name").text.strip,
          event_date: next_up[:time],
          price: nil,
          ticket_status: show_status(performances),
          link_to_buy_ticket: next_up[:url],
          more_info: next_up[:url][%r{\Ahttps?://[^/]+/shows/\d+}] || next_up[:url],
          venue: venue,
        }
      end

      EventValidator.validate!(events, venue: venue)

      ActiveRecord::Base.transaction do
        Event.where(venue: venue).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} #{venue} events in #{Time.now.to_i - start_time} seconds"

      events
    end

    def upcoming_performances(show)
      show.xpath("./events/event").filter_map do |event|
        iso = event.at_xpath("./date_time_iso")&.text
        next if iso.blank?

        time = Time.parse(iso).in_time_zone("Europe/Dublin")
        next if time < Time.current

        { time: time, status: event.at_xpath("./status")&.text.to_s.strip, url: event.at_xpath("./url")&.text }
      end
    end

    # Show status is the most-available tier across its upcoming performances —
    # one bookable date means the show is still catchable.
    def show_status(performances)
      tiers = performances.map { |performance| performance_tier(performance[:status]) }
      return :available if tiers.include?(:available)
      return :limited_availability if tiers.include?(:limited_availability)
      return :sold_out if tiers.any? && tiers.all?(:sold_out)

      :unknown
    end

    def performance_tier(status)
      case status.to_s.downcase
      when "available" then :available
      when /few|limited|low/ then :limited_availability
      when "sold out" then :sold_out
      else :unknown
      end
    end
  end
end
