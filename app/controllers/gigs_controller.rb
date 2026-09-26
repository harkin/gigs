class GigsController < ApplicationController
  def index
    # Loaded up front so the view's count comes off the loaded rows. The
    # database is remote, so a second query costs a whole round-trip.
    @events = Event.upcoming.order(:event_date).load
    @venues = Event.venues.keys.map { |venue| [ Event::VENUE_NAMES[venue], venue ] }
    @last_refreshed_at = Refresh.last&.last_refresh_at
    @layout = params[:layout].presence_in(%w[table cards]) || "table"
    @theme = params[:theme].presence_in(GigsHelper::THEMES.keys)

    expires_in 1.hour, public: false
  end

  def redesign
    events = Event.upcoming.order(:event_date).load
    @event_count = events.size
    @on_now, dated = events.partition { |event| event.multi_day? && event.event_date.to_date <= Date.current }
    @days = dated.group_by { |event| event.event_date.to_date }
    @venues = events.map(&:venue).uniq.map { |venue| [ Event::VENUE_NAMES[venue], venue ] }.sort
    @last_refreshed_at = Refresh.last&.last_refresh_at

    expires_in 1.hour, public: false
    render layout: "redesign"
  end

  def refresh
    Thread.new { ::RefreshGigData.refresh_events }
    redirect_to action: :index
  end
end
