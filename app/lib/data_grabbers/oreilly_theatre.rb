require "net/http"

module DataGrabbers
  # The O'Reilly Theatre site (a Weebly page) only shows poster images grouped
  # under month headings, with no event text and dates baked into the images.
  # Rather than OCR the posters, we follow each poster's ticket link out to the
  # provider (Ticketsolve, Fever, Eventbrite, GK Entertainment) and read the
  # real title/date/status from structured data there. If a provider can't be
  # parsed we fall back to the month heading + a title derived from the image
  # filename so the event is never lost.
  class OreillyTheatre

    EVENTS_URL = "https://www.oreillytheatre.com/"
    TICKETSOLVE_HOST = "https://takeyourseats.ticketsolve.com".freeze

    # Ticketsolve gates its JSON API behind a "queue-it" waiting room that
    # rejects non-browser requests, so we present as a browser throughout.
    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15".freeze
    DEFAULT_HEADERS = { "User-Agent" => USER_AGENT }.freeze

    MONTHS = %w[January February March April May June July August September October November December].freeze
    FILENAME_NOISE = (MONTHS.map(&:downcase) + %w[orig full final new copy sold out pm am]).freeze

    def self.get_events
      start_time = Time.now.to_i
      @ticketsolve_jar = Hash.new { |hash, host| hash[host] = {} }
      @ticketsolve_ready = false

      events = []

      scrape_homepage.each do |listing|
        resolved =
          begin
            resolve(listing)
          rescue => e
            puts "  O'Reilly: couldn't resolve #{listing[:link]} (#{e.class}: #{e.message})"
            nil
          end

        # nil means the provider lookup failed -> fall back to month/filename.
        # An empty array means it succeeded but had nothing upcoming -> skip.
        resolved = [fallback_event(listing)] if resolved.nil?

        # When a provider can't tell us availability, fall back to the venue's
        # own signal: a poster filename like "...-sold-out".
        poster_sold_out = listing[:filename].downcase.include?("sold-out")

        resolved.each do |event|
          status = event[:ticket_status]
          status = :sold_out if status == :unknown && poster_sold_out

          events.push(
            event.merge(
              ticket_status: status,
              link_to_buy_ticket: listing[:link],
              more_info: listing[:link],
              venue: :oreilly_theatre,
            )
          )
        end
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: :oreilly_theatre).delete_all
        Event.insert_all(events) if events.any?
      end

      puts "Finished grabbing #{events.count} O'Reilly Theatre events in #{Time.now.to_i - start_time} seconds"

      events
    end

    # --- Homepage --------------------------------------------------------------

    # Returns one listing per poster: { link:, filename:, month: }.
    def self.scrape_homepage
      document = Nokogiri::HTML(fetch(EVENTS_URL).body)
      listings = []

      month_headers = document.css("h2.wsite-content-title").select { |h| MONTHS.include?(h.text.strip) }

      month_headers.each do |header|
        month = header.text.strip
        node = header.next_element

        while node && !(node.name == "h2" && MONTHS.include?(node.text.strip))
          node.css("a").each do |anchor|
            image = anchor.at_css("img")
            link = anchor.attribute("href")&.value
            next unless image && link.present?

            listings << { link: link, filename: image.attribute("src")&.value.to_s, month: month }
          end
          node = node.next_element
        end
      end

      listings
    end

    # --- Dispatch --------------------------------------------------------------

    def self.resolve(listing)
      case URI.parse(listing[:link]).host.to_s
      when /ticketsolve\.com/             then resolve_ticketsolve(listing[:link])
      when /feverup\.com/, /eventbrite\./ then resolve_schema_event(listing[:link])
      when /gkentertainment/              then resolve_gk(listing[:link])
      end
    end

    # --- Ticketsolve (Ember SPA + JSON:API behind a queue-it wall) -------------

    def self.resolve_ticketsolve(url)
      show_id = url[%r{/shows/(\d+)}, 1]
      return unless show_id

      ensure_ticketsolve_session!(url)
      name = humanize_if_shouty(ticketsolve_api("shows/#{show_id}").dig("data", "attributes", "name").to_s.strip)

      performances = ticketsolve_api("events?filter%5Bshow%5D=#{show_id}&page%5Blimit%5D=50")["data"] || []

      performances.filter_map do |performance|
        attributes = performance["attributes"]
        day = attributes["day"]
        next if day.blank? || Date.parse(day) < Date.today

        {
          title: name,
          event_date: combine_day_and_time(day, attributes["time-of-day"]),
          ticket_status: attributes["soldout"] ? :sold_out : :available,
          price: nil,
        }
      end
    end

    # Visiting any Ticketsolve page bounces through the queue-it waiting room and
    # back; completing that redirect round-trip leaves a validated session the
    # JSON API accepts. It's session-wide, so bootstrap once per run.
    def self.ensure_ticketsolve_session!(seed_url)
      return if @ticketsolve_ready

      ticketsolve_http_get(seed_url)
      @ticketsolve_ready = true
    end

    def self.ticketsolve_api(path)
      JSON.parse(ticketsolve_http_get("#{TICKETSOLVE_HOST}/api/ticketbooth/v1/#{path}").body)
    end

    # Net::HTTP (rather than Faraday) so we can read Set-Cookie as a clean array
    # and follow the cross-domain redirect chain with a per-host cookie jar.
    def self.ticketsolve_http_get(url, redirect_limit: 10)
      redirect_limit.times do
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"

        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = USER_AGENT
        request["Accept"] = "application/vnd.api+json"
        cookies = @ticketsolve_jar[uri.host].map { |name, value| "#{name}=#{value}" }.join("; ")
        request["Cookie"] = cookies if cookies.present?

        response = http.request(request)
        (response.get_fields("set-cookie") || []).each do |raw|
          name, value = raw.split(";").first.to_s.split("=", 2)
          @ticketsolve_jar[uri.host][name.strip] = value if name && value
        end

        return response unless response.is_a?(Net::HTTPRedirection) && response["location"]

        url = URI.join(url, response["location"]).to_s
      end

      raise "Ticketsolve: too many redirects"
    end

    # time-of-day is a placeholder-dated ISO time (e.g. 2000-01-01T19:30:00),
    # so we keep only its clock time and attach it to the real day.
    def self.combine_day_and_time(day, time_of_day)
      clock = (Time.parse(time_of_day).strftime("%H:%M") if time_of_day.present?) rescue nil
      Time.parse([day, clock].compact.join(" "))
    end

    # --- Fever / Eventbrite (schema.org Event JSON-LD) -------------------------

    def self.resolve_schema_event(url)
      event = json_ld_event(url)
      return unless event && event["startDate"].present?

      [{
        title: humanize_if_shouty(event["name"].to_s.strip),
        event_date: Time.parse(event["startDate"]),
        ticket_status: offers_status(event["offers"]),
        price: lowest_offer_price(event["offers"]),
      }]
    end

    def self.json_ld_event(url)
      document = Nokogiri::HTML(fetch(url).body)
      objects = document.css('script[type="application/ld+json"]').flat_map do |script|
        parsed = JSON.parse(script.text) rescue nil
        parsed.is_a?(Array) ? parsed : [parsed]
      end
      objects.compact.find { |object| object["@type"] == "Event" }
    end

    def self.lowest_offer_price(offers)
      offers = [offers] unless offers.is_a?(Array)
      prices = offers.compact.flat_map { |offer| [offer["price"], offer["lowPrice"]] }.compact
      prices = prices.map { |p| p.to_s.to_f }.reject(&:zero?)
      return if prices.empty?

      format("€%g", prices.min)
    end

    # Maps schema.org offer availability to our ticket_status. Sold out only
    # when every offer says so; limited/in-stock if any offer does.
    def self.offers_status(offers)
      offers = [offers] unless offers.is_a?(Array)
      availabilities = offers.compact.map { |offer| offer["availability"].to_s }

      return :unknown if availabilities.empty?
      return :sold_out if availabilities.all? { |a| a.include?("SoldOut") }
      return :limited_availability if availabilities.any? { |a| a.include?("LimitedAvailability") }
      return :available if availabilities.any? { |a| a.include?("InStock") }

      :unknown
    end

    # --- GK Entertainment (date lives in og: meta prose) -----------------------

    def self.resolve_gk(url)
      document = Nokogiri::HTML(fetch(url).body)
      title = document.at_css('meta[property="og:title"]')&.[]("content").to_s
      description = document.at_css('meta[property="og:description"]')&.[]("content").to_s

      date_text = description[/\bon (\d{1,2}\s+[A-Za-z]+\s+\d{4})/, 1]
      return unless date_text

      # og:title looks like "Toxic – By Abhishek Upmanyu 5pm 24th July Dublin";
      # the time (when present) and the trailing date + city aren't part of the
      # show name, so pull the time out and strip both off the title.
      time_text = title[/\b\d{1,2}(:\d{2})?\s*[ap]m\b/i]
      clean_title = title
        .sub(/\b\d{1,2}(:\d{2})?\s*[ap]m\b/i, "")
        .sub(/\s*\d{1,2}(st|nd|rd|th)?\s+[A-Za-z]+\s+Dublin\s*\z/i, "")
        .squeeze(" ").strip

      [{
        title: humanize_if_shouty(clean_title.presence || title),
        event_date: Time.parse([date_text, time_text].compact.join(" ")),
        ticket_status: :unknown,
        price: nil,
      }]
    end

    # --- Fallback & shared helpers ---------------------------------------------

    def self.fallback_event(listing)
      {
        title: title_from_filename(listing[:filename]),
        event_date: first_of_month(listing[:month]),
        ticket_status: listing[:filename].downcase.include?("sold-out") ? :sold_out : :unknown,
        price: nil,
      }
    end

    def self.title_from_filename(src)
      base = File.basename(src.split("?").first.to_s, ".*")
      tokens = base.split(/[-_]/).reject do |token|
        token.empty? || token.match?(/\A\d+\z/) || FILENAME_NOISE.include?(token.downcase)
      end
      (tokens.join(" ").titleize.presence || base.tr("-_", " ").titleize)
    end

    def self.first_of_month(month)
      month_number = MONTHS.index(month) + 1
      year = Date.today.year
      year += 1 if month_number < Date.today.month
      Time.new(year, month_number, 1)
    end

    # Organisers sometimes type names in ALL CAPS. Title-case those while
    # preserving the original punctuation and spacing (unlike titleize, which
    # drops hyphens), and leave mixed-case names (e.g. "...The Killer AI") alone.
    def self.humanize_if_shouty(title)
      return title if title.blank? || title != title.upcase

      title.split(/(\s+)/).map { |part| part.match?(/\A\s+\z/) ? part : part.capitalize }.join
    end

    # Faraday has no redirect middleware here, so follow redirects manually.
    # (Ticketsolve's queue-it bootstrap needs per-host cookies, so it uses its
    # own Net::HTTP path above rather than this helper.)
    def self.fetch(url, headers: {}, limit: 5)
      response = Faraday.get(url, nil, DEFAULT_HEADERS.merge(headers))

      if response.status.between?(300, 399) && limit.positive?
        location = response.headers["location"]
        return fetch(URI.join(url, location).to_s, headers: headers, limit: limit - 1) if location.present?
      end

      response
    end

  end
end
