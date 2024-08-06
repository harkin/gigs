module DataGrabbers
  class VicarStreet

    EVENTS_URL = "https://www.vicarstreet.com/all-shows-at-vicar-street.html"
    ROOT_URL = "https://www.vicarstreet.com"

    def self.get_events
      start_time = Time.now.to_i

      events = []

      # this defaults to form encoding which Whelans expects
      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)
      main_body = document.css("div.blog-featured")
      next_page = main_body.css("li.pagination-next").css("a").attribute("href").value
      extract_events_from_html(main_body, events)

      while next_page
        response = Faraday.get("#{ROOT_URL}#{next_page}")
        document = Nokogiri::HTML(response.body)
        main_body = document.css("div.blog-featured")
        next_page = main_body.css("li.pagination-next").css("a")&.attribute("href")&.value
        extract_events_from_html(main_body, events)
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :vicar_street).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Vicar Street events in #{Time.now.to_i - start_time} seconds"

      events
    end

    def self.extract_events_from_html(html, events)
      listings = html.css("div.upcomingShowWrap")
      listings.each do |listing|
        name_col = listing.css("span.name_col")
        ticket_col = listing.css("span.ticket_col")
        start_time = name_col.css("meta").find { |m| m.attribute("itemprop").value.eql?("startDate") }.attribute("content").value
        events.push(
          {
            title: name_col.css("a").text.strip,
            event_date: Time.parse(start_time),
            ticket_status: ticket_col.text.strip.eql?("Tickets") ? :available : :sold_out,
            link_to_buy_ticket: ticket_col.css("a").attribute("href").value,
            more_info: "#{ROOT_URL}#{name_col.css("a").attribute("href").value}",
            venue: :vicar_street,
          }
        )
      end
    end

  end
end
