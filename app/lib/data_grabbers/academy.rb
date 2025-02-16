module DataGrabbers
  class Academy

    EVENTS_URL = "https://www.theacademydublin.com/"

    def self.get_events
      start_time = Time.now.to_i

      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)
      gigs = document.css("div.month, div.gigbg")
      current_month = gigs.css("span.headingfour").first.text
      events = []
      gigs.each do |gig|
        if gig.css("span.headingfour").present?
          current_month = gig.css("span.headingfour").text
        else
          details = gig.css("div.details").text.split("/")
          date = "#{details[0].strip} #{gig.css("div.date").text} #{current_month}"

          events.push(
            {
              title: gig.css("div.bands").text,
              event_date: Time.parse(date),
              price: details[2]&.strip,
              ticket_status: gig.css("div.soldout").blank? ? :available : :sold_out,
              link_to_buy_ticket: gig.css("a").attribute("href")&.value,
              venue: :academy,
            }
          )
        end
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :academy).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} The Academy events in #{Time.now.to_i - start_time} seconds"
      events
    end
  end
end
