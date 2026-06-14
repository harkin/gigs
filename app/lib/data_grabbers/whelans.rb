module DataGrabbers
  class Whelans

    EVENTS_URL = "https://www.whelanslive.com/events/"
    # The events page shows no availability; ticket sales run through Whelan's
    # WooCommerce store, whose public Store API reports stock per product.
    STORE_API_URL = "https://www.whelanslive.com/wp-json/wc/store/v1/products"

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

      apply_ticket_statuses(events)

      EventValidator.validate!(events, venue: :whelans)

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

        next if title.include?("CANCELLED")

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

    # Map each event to its store stock via one batched Store API lookup keyed on
    # the ticket slug. Events with no matching product stay :unknown.
    def self.apply_ticket_statuses(events)
      slugs = events.filter_map { |event| ticket_slug(event[:link_to_buy_ticket]) }.uniq
      status_by_slug = fetch_store_statuses(slugs)

      events.each do |event|
        event[:ticket_status] = status_by_slug.fetch(ticket_slug(event[:link_to_buy_ticket]), :unknown)
      end
    end

    def self.fetch_store_statuses(slugs)
      slugs.each_slice(50).each_with_object({}) do |batch, statuses|
        products = JSON.parse(Faraday.get(STORE_API_URL, slug: batch.join(","), per_page: 100).body)
        raise "Whelans: unexpected Store API response" unless products.is_a?(Array)

        products.each { |product| statuses[product["slug"]] = store_status(product) }
      end
    end

    def self.store_status(product)
      return :sold_out unless product["is_in_stock"]
      return :limited_availability if product["low_stock_remaining"]

      :available
    end

    def self.ticket_slug(url)
      url.to_s[%r{/ticket/([^/]+)/?}, 1]
    end

  end
end