class PreviousDatabase < ActiveRecord::Base
  self.abstract_class = true
end

class PreviousEvent < PreviousDatabase
  self.table_name = "events"
end

class PreviousRefresh < PreviousDatabase
  self.table_name = "refreshes"
end

namespace :gigs do
  desc "One-off: replace all data with a copy from the previous MySQL database"
  task import_previous_database: :environment do
    credentials = Rails.application.credentials.planetscale
    PreviousDatabase.establish_connection(
      adapter: "trilogy", encoding: "utf8mb4", ssl_mode: "verify_identity", connect_timeout: 15,
      **credentials.slice(:host, :username, :password, :database, :ssl_mode)
    )

    events = PreviousEvent.all.map(&:attributes)
    refreshes = PreviousRefresh.all.map(&:attributes)
    raise "The previous database has no events" if events.empty?

    ActiveRecord::Base.transaction do
      Event.delete_all
      Refresh.delete_all
      Event.insert_all(events)
      Refresh.insert_all(refreshes) if refreshes.any?
    end

    puts "Imported #{events.count} events and #{refreshes.count} refreshes"
  end

  # For when the previous database can't be read. Run it straight after the first
  # refresh into an empty database, which would otherwise mark every gig as new.
  desc "One-off: clear first_seen_at so existing gigs don't show as newly announced"
  task forget_first_seen: :environment do
    puts "Cleared first_seen_at on #{Event.update_all(first_seen_at: nil)} events"
  end
end
