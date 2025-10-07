module DataGrabbers
  class Whelans

    EVENTS_URL = "https://www.whelanslive.com/events/"

    def self.get_events
      start_time = Time.now.to_i

      events = []

      response = Faraday.get(EVENTS_URL)
      document = Nokogiri::HTML(response.body)
      articles = document.css("article.desk")

      articles.each do |article|
        title_element = article.css("h3 a").first
        title = title_element.text.strip
        more_info = title_element.attribute("href")&.value

        date_text = article.css("li").find { |li| li.text.include?("@") }&.text&.strip

        # dates look like "Tuesday, 7th of October @ 8:00 PM"
        # the 'of' interferes with parsing
        date_text.gsub!("of", "")

        ticket_element = article.css("a.tickets").first
        ticket = ticket_element&.attribute("href")&.value

        event_date = Time.parse(date_text)

        events.push(
          {
            title: title,
            event_date: event_date,
            ticket_status: :unknown,
            link_to_buy_ticket: ticket,
            more_info: more_info,
            venue: :whelans,
          }
        )
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