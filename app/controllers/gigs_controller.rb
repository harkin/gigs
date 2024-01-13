class GigsController < ApplicationController
  def index
    puts "hello"
    events_by_year = Event.order(:event_date).group_by {|event| event.event_date.year}
    @events = Hash[events_by_year.map { |k, events| [k, events.group_by { |event| event.event_date.month }] }]
  end

  def refresh
    puts "refreshing gig events"
    ::Refresh.refresh_events
    redirect_to action: :index
  end
end
