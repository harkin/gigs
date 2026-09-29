require "test_helper"

class GigsHelperTest < ActionView::TestCase
  test "external_url passes http and https through" do
    assert_equal "https://dice.fm/event/abc", external_url("https://dice.fm/event/abc")
    assert_equal "http://example.com/x", external_url("http://example.com/x")
    assert_equal "HTTPS://example.com/x", external_url("HTTPS://example.com/x")
  end

  test "external_url drops schemes the browser should not follow" do
    assert_nil external_url("javascript:alert(1)")
    assert_nil external_url("data:text/html,<script>alert(1)</script>")
    assert_nil external_url("/relative/path")
    assert_nil external_url(nil)
    assert_nil external_url("")
  end

  def event(attributes = {})
    Event.new({ title: "Test", event_date: Time.zone.parse("2026-09-24 19:30"), ticket_status: :available, venue: :academy }.merge(attributes))
  end

  test "display_time hides stored midnight and multi-day runs" do
    assert_equal "19:30", display_time(event)
    assert_nil display_time(event(event_date: Time.zone.parse("2026-09-24 00:00")))
    assert_nil display_time(event(end_date: Time.zone.parse("2026-10-18")))
  end

  test "event_link prefers the ticket link and drops unsafe schemes" do
    assert_equal "https://t.example/a", event_link(event(link_to_buy_ticket: "https://t.example/a", more_info: "https://i.example/b"))
    assert_equal "https://i.example/b", event_link(event(link_to_buy_ticket: "javascript:alert(1)", more_info: "https://i.example/b"))
    assert_nil event_link(event)
  end
end
