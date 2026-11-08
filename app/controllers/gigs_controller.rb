class GigsController < ApplicationController
  def index
    # Loaded up front so size and the groupings below reuse these rows rather
    # than each issuing its own query.
    events = Event.upcoming.order(:event_date).load
    @event_count = events.size
    @on_now, dated = events.partition { |event| event.multi_day? && event.event_date.to_date <= Date.current }
    @days = dated.group_by { |event| event.event_date.to_date }
    @venues = events.map(&:venue).uniq.map { |venue| [ Event::VENUE_NAMES[venue], venue ] }.sort
    @last_refreshed_at = Refresh.last&.last_refresh_at

    expires_in 1.hour, public: false
  end
end
