module DataGrabbers
  class Academy

    # The Academy's site is a Next.js app that fetches its event list from the
    # VenueCloud API (venueCloudId=21 is The Academy). We hit that JSON API
    # directly rather than scraping the rendered HTML -- it's the same data the
    # page hydrates from, and it doesn't break when they tweak their markup.
    # Covers all the venue's rooms (The Academy, The Academy 2, The Green Room,
    # ...), all tagged as :academy.
    EVENTS_URL = "https://www.venuecloud.net/api/events?venueCloudId=21"

    # Affiliate/analytics params the ticket sellers (mostly dice.fm) bolt on.
    TRACKING_PARAM = /\A(?:utm_|dice_)/

    def self.get_events
      Store.replace(:academy) do
        response = Faraday.get(EVENTS_URL)
        raw_events = JSON.parse(response.body)["events"] || []

        raw_events.map do |gig|
          ticket_url = clean_ticket_url(gig["ticketsUrl"])

          {
            # subTitle (when present) is usually a support act, e.g. "+ Special
            # Guests: ...", so a plain space reads better than a dash.
            title: [gig["title"], gig["subTitle"]].compact_blank.join(" "),
            event_date: Time.parse(gig.dig("startDate", "date")),
            price: gig["pricing"],
            ticket_status: gig["isSoldOut"] ? :sold_out : :available,
            link_to_buy_ticket: ticket_url,
            # The Academy has no per-event page of its own; its Ticketmaster
            # listing is the only detail page, so it doubles as more_info.
            more_info: ticket_url,
            venue: :academy,
          }
        end
      end
    end

    # Strips tracking params so we store the bare event link. Also drops
    # valueless params: VenueCloud cuts ticketsUrl off at 256 characters, which
    # can leave a half-written param name on the end.
    def self.clean_ticket_url(url)
      return url if url.blank?

      uri = URI.parse(url)
      return url if uri.query.blank?

      kept = URI.decode_www_form(uri.query)
                .reject { |name, value| name.match?(TRACKING_PARAM) || value.blank? }
      uri.query = kept.presence && URI.encode_www_form(kept)
      uri.to_s
    end
  end
end
