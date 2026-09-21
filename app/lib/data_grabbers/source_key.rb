module DataGrabbers
  # Matches a scraped gig to the row it is about to replace, so first_seen_at
  # survives a refresh.
  module SourceKey
    module_function

    def for(venue, event)
      [ venue.to_s, identifier(event), timestamp(event[:event_date]) ]
    end

    # Ticket links are nil for whole venues and carry per-performance ids that
    # churn, so a venue's own listing page is the steadier handle; the title is
    # a last resort.
    def identifier(event)
      normalise_url(event[:more_info]).presence ||
        normalise_url(event[:link_to_buy_ticket]).presence ||
        event[:title].to_s.strip.gsub(/[[:space:]]+/, " ").downcase
    end

    def normalise_url(url)
      return "" if url.blank?

      url.to_s.strip.downcase
         .sub(/\Ahttp:/, "https:")
         .sub(/#.*\z/, "")
         .sub(%r{/\z}, "")
    end

    # Grabbers return either a Date or a Time, and a bare Date is stored as
    # midnight UTC, so both have to normalise the same way to match.
    def timestamp(value)
      value = value.to_time(:utc) if value.is_a?(Date) && !value.is_a?(DateTime)
      value.to_time.utc.iso8601
    end
  end
end
