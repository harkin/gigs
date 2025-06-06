module DataGrabbers
  class Whelans

    EVENTS_URL = "https://www.whelanslive.com/wp-content/plugins/modus-whelans/inc/custom-ajax.php"

    def self.get_events
      return

      start_time = Time.now.to_i

      events = []

      (0..11).each do |i|
        date_to_search_for = Time.now + i.months
        # Whelans expects a date of the form "2024-3" to be sent in the request
        month_array = "#{date_to_search_for.year}-#{date_to_search_for.month}"

        # this defaults to form encoding which Whelans expects
        response = Faraday.post(EVENTS_URL, {
          action: "whelansAjaxEventShortcode",
          ajax_flag: 1,
          page: 1,
          limit: 200, # This seems to work, unlikely to have more than 200 events in a month and can avoid paging this way
          class: "events-template",
          month_array: month_array,
        })
        document = Nokogiri::HTML(response.body)
        gigs = document.css("li")

        gigs.each do |gig|
          day_of_month = gig.css("div.date")[0].children[1].text
          time = gig.css("div.date")[0].children[2].text
          title = gig.css("div.titles").css("a").text
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
        Event.where(venue: :whelans).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Whelans events in #{Time.now.to_i - start_time} seconds"

      events
    end

  end
end