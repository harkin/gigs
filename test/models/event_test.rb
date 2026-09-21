require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "every venue in the enum has a display name" do
    assert_equal Event.venues.keys.sort, Event::VENUE_NAMES.keys.sort
  end

  test "renderable_venue reads the display name" do
    assert_equal "The 3Arena", Event.new(venue: :point).renderable_venue
    assert_equal "The Workman's Club", Event.new(venue: :workmans).renderable_venue
  end

  test "newly_announced covers the window and nothing older" do
    fresh = create_event(title: "Fresh", first_seen_at: 2.days.ago)
    stale = create_event(title: "Stale", first_seen_at: 8.days.ago, more_info: "https://example.com/2")

    assert_equal ["Fresh"], Event.newly_announced.pluck(:title)
    assert_predicate fresh, :newly_announced?
    assert_not_predicate stale, :newly_announced?
  end

  test "an event with no first_seen_at is not newly announced" do
    assert_not_predicate create_event(title: "Unknown Origin"), :newly_announced?
  end

  def create_event(title:, first_seen_at: nil, more_info: "https://example.com/1")
    Event.create!(title: title, venue: :academy, ticket_status: :available,
                  event_date: 1.week.from_now, more_info: more_info, first_seen_at: first_seen_at)
  end

  test "renderable_ticket_status titleises each status" do
    expected = {
      "available" => "Available",
      "limited_availability" => "Limited Availability",
      "sold_out" => "Sold Out",
      "unknown" => "Unknown",
    }
    expected.each do |status, rendered|
      assert_equal rendered, Event.new(ticket_status: status).renderable_ticket_status
    end
  end
end
