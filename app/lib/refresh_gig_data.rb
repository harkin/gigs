class RefreshGigData

  def self.refresh_events
    puts "Starting to refresh all gig data"
    start_time = Time.now.to_i

    ::DataGrabbers::Academy.get_events
    ::DataGrabbers::ButtonFactory.get_events
    ::DataGrabbers::Olympia.get_events
    ::DataGrabbers::Point.get_events
    ::DataGrabbers::VicarStreet.get_events
    ::DataGrabbers::Whelans.get_events

    Refresh.destroy_all
    Refresh.create!(last_refresh_at: Time.now)

    puts "Finished refreshing all gig data in #{Time.now.to_i - start_time} seconds"
  end
end
