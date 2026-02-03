module DataGrabbers
  class Whelans

    EVENTS_URL = "https://www.whelanslive.com/events/"

    def self.get_events
      start_time = Time.now.to_i

      events = []

      next_page = EVENTS_URL
      next_year = false

      12.times do
        response = Faraday.get("#{next_page}")
        document = Nokogiri::HTML(response.body)
        events_html = document.css("article.desk")

        extract_events_from_html(events_html, events, next_year)

        next_page = document.css("header nav").last.css("a").last.attribute("href").to_s + "/"
        next_year = true if next_page.include?("january")
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :whelans).delete_all
        Event.insert_all(events)
      end

      puts "Finished grabbing #{events.count} Whelans events in #{Time.now.to_i - start_time} seconds"

      events
    end

    def self.extract_events_from_html(events_html, events, next_year)
      events_html.each do |event_html|
        title_element = event_html.css("h3 a").first
        title = title_element.text.strip
        more_info = title_element.attribute("href")&.value

        date_text = event_html.css("li").find { |li| li.text.include?("@") }&.text&.strip

        # dates look like "Tuesday, 7th of October @ 8:00 PM"
        # the 'of' interferes with parsing
        date_text.gsub!("of", "")

        ticket_element = event_html.css("a.tickets").first
        ticket = ticket_element&.attribute("href")&.value

        price_element = event_html.css("li.price").first
        price = price_element&.text&.strip

        event_date = Time.parse(date_text)
        if next_year
          event_date = event_date + 1.year
        end

        events.push(
          {
            title: title,
            event_date: event_date,
            price: price,
            ticket_status: :unknown,
            link_to_buy_ticket: ticket,
            more_info: more_info,
            venue: :whelans,
          }
        )
      end

    end

  end
end