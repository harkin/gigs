require "test_helper"

class RedesignHelperTest < ActionView::TestCase
  include GigsHelper

  def event(attributes = {})
    Event.new({ title: "Test", event_date: Time.zone.parse("2026-09-24 19:30"), ticket_status: :available, venue: :academy }.merge(attributes))
  end

  test "display_price tidies the common shapes" do
    assert_equal "€24.50", display_price("24.50")
    assert_equal "from €14.50", display_price("FROM €14.50")
    assert_equal "from €14.50", display_price("FROM  €14.50")
    assert_equal "from €21.85", display_price("From €21.85")
    assert_equal "€15", display_price("€15.00")
    assert_equal "from €20", display_price("FROM €20")
  end

  test "display_price passes unusual shapes through" do
    assert_equal "Free", display_price("Free")
    assert_equal "€9.50 - €12", display_price("€9.50 - €12.00")
    assert_equal "€25 + bkng fee", display_price("€25.00 + bkng fee")
    assert_equal "€12,50", display_price("€12,50")
    assert_nil display_price(nil)
    assert_nil display_price(" ")
  end

  test "title_case_shouting only touches all-caps titles" do
    assert_equal "Westside Cowboy", title_case_shouting("WESTSIDE COWBOY")
    assert_equal "An Bothar Abhaile", title_case_shouting("AN BOTHAR ABHAILE")
    assert_equal "Whelan's Indie Club", title_case_shouting("WHELAN'S INDIE CLUB")
    assert_equal "Tradition Now: Ispíní na hÉireann", title_case_shouting("Tradition Now: Ispíní na hÉireann")
    assert_equal "CURVEBALL: Nova Dream", title_case_shouting("CURVEBALL: Nova Dream")
  end

  test "title_case_shouting keeps acronyms, initials and tokens with digits" do
    assert_equal "U2BABY – The Reinvention", title_case_shouting("U2BABY – THE REINVENTION")
    assert_equal "A.S. Fanning", title_case_shouting("A.S. FANNING")
    assert_equal "Genitorturers \"Live + Lewd\" UK Tour", title_case_shouting("GENITORTURERS \"LIVE + LEWD\" UK TOUR")
  end

  test "a sold-out marker in the title becomes the status" do
    sold = event(title: "Gurriers Outstore Performance (SOLD OUT)", ticket_status: :unknown)

    assert_equal "sold_out", display_status(sold)
    assert_equal "Gurriers Outstore Performance", display_title(sold)
    assert_equal "available", display_status(event)
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
