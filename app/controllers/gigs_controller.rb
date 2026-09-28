class GigsController < ApplicationController
  def index
    # Loaded up front so the counts come off the loaded rows. The database is
    # remote, so a second query costs a whole round-trip.
    events = Event.upcoming.order(:event_date).load
    @event_count = events.size
    @on_now, dated = events.partition { |event| event.multi_day? && event.event_date.to_date <= Date.current }
    @days = dated.group_by { |event| event.event_date.to_date }
    @venues = events.map(&:venue).uniq.map { |venue| [ Event::VENUE_NAMES[venue], venue ] }.sort
    @last_refreshed_at = Refresh.last&.last_refresh_at

    expires_in 1.hour, public: false
  end
end
