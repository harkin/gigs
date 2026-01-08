class GigsController < ApplicationController
  def index
    @events = Event.order(:event_date)
    @venues = Event.venues.keys.map { |v| [Event.new(venue: v).renderable_venue, v] }
    @last_refreshed_at = Refresh.last&.last_refresh_at
  end

  def refresh
    puts "refreshing gig events"
    ::RefreshGigData.refresh_events
    redirect_to action: :index
  end
end
