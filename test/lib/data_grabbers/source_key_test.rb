require "test_helper"

class DataGrabbers::SourceKeyTest < ActiveSupport::TestCase
  def event(**overrides)
    { title: "Some Gig", event_date: Time.utc(2026, 11, 1, 19, 0),
      more_info: "https://example.com/shows/1", link_to_buy_ticket: nil }.merge(overrides)
  end

  test "is stable for the same gig" do
    assert_equal DataGrabbers::SourceKey.for(:academy, event),
                 DataGrabbers::SourceKey.for(:academy, event)
  end

  test "ignores a title rewrite" do
    assert_equal DataGrabbers::SourceKey.for(:academy, event),
                 DataGrabbers::SourceKey.for(:academy, event(title: "Some Gig Plus Special Guests"))
  end

  test "separates two performances on the same day" do
    matinee = DataGrabbers::SourceKey.for(:academy, event(event_date: Time.utc(2026, 11, 1, 14, 0)))
    evening = DataGrabbers::SourceKey.for(:academy, event(event_date: Time.utc(2026, 11, 1, 19, 0)))

    assert_not_equal matinee, evening
  end

  test "separates the same show at different venues" do
    assert_not_equal DataGrabbers::SourceKey.for(:academy, event),
                     DataGrabbers::SourceKey.for(:whelans, event)
  end

  test "separates different shows" do
    assert_not_equal DataGrabbers::SourceKey.for(:academy, event),
                     DataGrabbers::SourceKey.for(:academy, event(more_info: "https://example.com/shows/2"))
  end

  test "treats cosmetic url differences as the same gig" do
    canonical = DataGrabbers::SourceKey.for(:academy, event)

    [ "http://example.com/shows/1", "https://example.com/shows/1/",
      "HTTPS://Example.com/shows/1", "  https://example.com/shows/1  ",
      "https://example.com/shows/1#tickets" ].each do |variant|
      assert_equal canonical, DataGrabbers::SourceKey.for(:academy, event(more_info: variant)),
                   "expected #{variant.inspect} to match the canonical url"
    end
  end

  test "falls back to the ticket link then the title when there is no info url" do
    by_ticket = DataGrabbers::SourceKey.for(:academy, event(more_info: nil, link_to_buy_ticket: "https://tickets.example/1"))
    assert_equal by_ticket,
                 DataGrabbers::SourceKey.for(:academy, event(more_info: "", link_to_buy_ticket: "https://tickets.example/1"))

    by_title = DataGrabbers::SourceKey.for(:academy, event(more_info: nil, link_to_buy_ticket: nil))
    assert_not_equal by_ticket, by_title
    assert_equal by_title,
                 DataGrabbers::SourceKey.for(:academy, event(more_info: nil, link_to_buy_ticket: nil, title: "  some   gig  "))
  end

  test "reads a bare Date the way it is stored" do
    assert_equal DataGrabbers::SourceKey.for(:academy, event(event_date: Time.utc(2026, 11, 1, 0, 0))),
                 DataGrabbers::SourceKey.for(:academy, event(event_date: Date.new(2026, 11, 1)))
  end
end
