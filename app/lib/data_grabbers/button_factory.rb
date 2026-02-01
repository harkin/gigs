module DataGrabbers
  class ButtonFactory

    EVENTS_URL = "https://buttonfactory.ie/shows"
    EVENTS_URI = URI.parse(EVENTS_URL)

    def self.get_events
      start_time = Time.now.to_i

      events = []

      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)
      gigs = document.css("div.eventlist--upcoming").css("article.eventlist-event")

      gigs.each do |gig|
        title = gig.css("h1.eventlist-title").text
        date = gig.css("time.event-date").text
        time = gig.css("time.event-time-12hr-start").text
        more_info_relative_link = gig.css("a.eventlist-button").attribute("href").value
        more_info_uri = URI.parse(more_info_relative_link)
        more_info_uri.scheme = EVENTS_URI.scheme
        more_info_uri.host = EVENTS_URI.host
        event_date = Time.parse("#{time} #{date}")

        next if event_date < Time.now

        events.push(
          {
            title: title,
            event_date: event_date,
            ticket_status: :unknown, # TODO Button Factory doesn't have ticket details on the shows page
            link_to_buy_ticket: nil, # TODO Button Factory doesn't have ticket links on the shows page
            more_info: more_info_uri.to_s,
            venue: :button_factory,
          }
        )
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :button_factory).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Button Factory events in #{Time.now.to_i - start_time} seconds"

      events
    end

  end
end