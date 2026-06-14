module DataGrabbers
  # Catches silent scraper drift: a venue changing its markup/API so events
  # still parse, but into garbage (blank titles, no dates, an empty list).
  # Raising aborts the fail-loud refresh; call it before delete_all/insert_all
  # so a bad scrape can't wipe good data.
  module EventValidator
    module_function

    # Years out; a date beyond this is a mis-parse, not a real gig.
    MAX_HORIZON = 3

    def validate!(events, venue:, min_count: 1)
      if events.size < min_count
        raise "#{venue}: parsed #{events.size} events (expected >= #{min_count}) — markup/API likely changed"
      end

      events.each do |event|
        raise "#{venue}: blank title in #{event.inspect}" if event[:title].blank?
        raise "#{venue}: missing event_date in #{event.inspect}" if event[:event_date].blank?

        date = event[:event_date].to_date
        if date > MAX_HORIZON.years.from_now.to_date
          raise "#{venue}: implausible event_date #{date} in #{event.inspect} — date parsing likely broke"
        end
      end
    end
  end
end
