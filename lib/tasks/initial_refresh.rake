namespace :gigs do
  # A scrape into an empty database would mark every gig as newly announced.
  # Guarded on Refresh, which is only written once a whole refresh succeeds, so
  # it can be rerun after a failed attempt but never after a real refresh.
  desc "One-off: first refresh into an empty database, without marking every gig as new"
  task initial_refresh: :environment do
    raise "A refresh has already run; use gigs:refresh" if Refresh.exists?

    ::RefreshGigData.refresh_events
    puts "Cleared first_seen_at on #{Event.update_all(first_seen_at: nil)} events"
  end
end
