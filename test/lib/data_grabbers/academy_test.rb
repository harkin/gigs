require "test_helper"

class DataGrabbers::AcademyTest < ActiveSupport::TestCase
  def clean(url)
    DataGrabbers::Academy.clean_ticket_url(url)
  end

  test "drops dice affiliate and utm params" do
    assert_equal "https://dice.fm/partner/tickets/event/7dwxmb-index-tickets",
                 clean("https://dice.fm/partner/tickets/event/7dwxmb-index-tickets?dice_id=9896602&dice_channel=web&dice_campaign=INDEX&utm_source=web")
  end

  test "drops a param name left half-written by the API's 256-character cut-off" do
    assert_equal "https://dice.fm/event/l8kv7r-lane-8-tickets",
                 clean("https://dice.fm/event/l8kv7r-lane-8-tickets?utm_source=ig&ut")
  end

  test "keeps params the ticket page actually needs" do
    assert_equal "https://tickets.the30plus.club/e/123?modal_widget=true&widget=true",
                 clean("https://tickets.the30plus.club/e/123?modal_widget=true&widget=true&utm_source=web")
    assert_equal "https://link.dice.fm/abc?sharer_id=6558bb97b703fb0001059d54",
                 clean("https://link.dice.fm/abc?sharer_id=6558bb97b703fb0001059d54")
  end

  test "leaves the question mark off when nothing survives" do
    assert_equal "https://dice.fm/event/abc-tickets",
                 clean("https://dice.fm/event/abc-tickets?utm_source=ig&utm_medium=social")
  end

  test "passes through urls without a query and blank values" do
    assert_equal "https://www.ticketmaster.ie/event/12345", clean("https://www.ticketmaster.ie/event/12345")
    assert_nil clean(nil)
    assert_equal "", clean("")
  end
end
