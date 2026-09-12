require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "every venue in the enum has a display name" do
    assert_equal Event.venues.keys.sort, Event::VENUE_NAMES.keys.sort
  end

  test "renderable_venue reads the display name" do
    assert_equal "The 3Arena", Event.new(venue: :point).renderable_venue
    assert_equal "The Workman's Club", Event.new(venue: :workmans).renderable_venue
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
