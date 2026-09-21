module DataGrabbers
  # Every grabber ends the same way: sanity-check what the scrape returned, then
  # swap the venue's rows for it in a single transaction so a partial write can't
  # leave the listing half-empty. The block returns the parsed events.
  module Store
    module_function

    def replace(venue, min_count: 1)
      start_time = Time.now.to_i

      events = yield

      EventValidator.validate!(events, venue: venue, min_count: min_count)

      now = Time.current
      already_seen = first_seen_at_by_key(venue)
      # fetch, not ||: a row stored before first_seen_at existed matches and keeps
      # its nil rather than being announced now.
      rows = events.map do |event|
        event.merge(first_seen_at: already_seen.fetch(SourceKey.for(venue, event), now))
      end

      ActiveRecord::Base.transaction do
        Event.where(venue: venue).delete_all
        Event.insert_all(rows) if rows.any?
      end

      puts "Finished grabbing #{events.count} #{Event::VENUE_NAMES.fetch(venue.to_s, venue)} events in #{Time.now.to_i - start_time} seconds"

      events
    end

    def first_seen_at_by_key(venue)
      Event.where(venue: venue)
           .pluck(:title, :event_date, :more_info, :link_to_buy_ticket, :first_seen_at)
           .to_h do |title, event_date, more_info, link_to_buy_ticket, first_seen_at|
             key = SourceKey.for(venue, { title: title, event_date: event_date,
                                          more_info: more_info, link_to_buy_ticket: link_to_buy_ticket })
             [ key, first_seen_at ]
           end
    end
  end
end
