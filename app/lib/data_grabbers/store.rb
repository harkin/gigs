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

      ActiveRecord::Base.transaction do
        Event.where(venue: venue).delete_all
        Event.insert_all(events) if events.any?
      end

      puts "Finished grabbing #{events.count} #{Event::VENUE_NAMES.fetch(venue.to_s, venue)} events in #{Time.now.to_i - start_time} seconds"

      events
    end
  end
end
