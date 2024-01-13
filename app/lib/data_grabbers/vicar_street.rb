module DataGrabbers
  class VicarStreet

    EVENTS_URL = "https://www.vicarstreet.com/all-shows-at-vicar-street.html"

    def self.get_events
      start_time = Time.now.to_i

      events = []

      (0..11).each do |i|
        date_to_search_for = Time.now + i.months
        # Whelans expects a date of the form "2024-3" to be sent in the request
        month_array = "#{date_to_search_for.year}-#{date_to_search_for.month}"


        # this defaults to form encoding which Whelans expects
        response = Faraday.get(EVENTS_URL)
        document = Nokogiri::HTML(response.body)
        gigs = document.css("div.upcomingShowWrap")

        gigs.each do |gig|
          date = gig.css("span.date_col").text.strip
          title = gig.css("span.name_col")[0].css("span").text
          time = gig.css("span.name_col")[0].css("meta").map(&:values).select { |h| h[0].eql?("startDate") }[0][1]
          
          more_info = gig.css("div.titles").css("a").attribute("href").value
          ticket = gig.css("div.link-types").css("a").attribute("href").value

          events.push(
            {
              title: title,
              event_date: Time.parse("#{month_array}-#{day_of_month} #{time}"),
              ticket_status: :unknown, # TODO can't tell if Whelans updates anything if a show sells out yet
              link_to_buy_ticket: ticket,
              more_info: more_info,
              venue: :whelans,
            }
          )
        end
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :vicar_street).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Whelans events in #{Time.now.to_i - start_time} seconds"

      events
    end

  end
end