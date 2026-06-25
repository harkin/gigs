class GigsController < ApplicationController
  def index
    @events = Event.upcoming.order(:event_date)
    @venues = Event.venues.keys.map { |v| [Event.new(venue: v).renderable_venue, v] }
    @last_refreshed_at = Refresh.last&.last_refresh_at
    @layout = params[:layout].presence_in(%w[table cards]) || "table"
    @theme = params[:theme].presence_in(GigsHelper::THEMES)

    expires_in 1.hour, public: false
  end

  def refresh
    Thread.new { ::RefreshGigData.refresh_events }
    redirect_to action: :index
  end
end
