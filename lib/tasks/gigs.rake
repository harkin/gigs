namespace :gigs do
  desc "Refresh gig data from all venue sources"
  task refresh: :environment do
    ::RefreshGigData.refresh_events
  end
end
