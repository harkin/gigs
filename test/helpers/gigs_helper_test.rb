require "test_helper"

class GigsHelperTest < ActionView::TestCase
  def title_for(title)
    event_title(Event.new(title: title))
  end

  test "decodes numeric entities from feeds that ship encoded titles" do
    assert_equal "Bluey’s Big Play", title_for("Bluey&#8217;s Big Play")
  end

  test "decodes named entities" do
    assert_equal "Metric, Broken Social Scene & Stars", title_for("Metric, Broken Social Scene &amp; Stars")
    assert_equal "Troy Hawke:  Never Stop", title_for("Troy Hawke:&nbsp; Never Stop")
  end

  test "leaves already-decoded titles alone" do
    assert_equal "St. Paul & The Broken Bones", title_for("St. Paul & The Broken Bones")
    assert_equal "Plain Title", title_for("Plain Title")
  end

  test "decodes encoded markup to inert text" do
    assert_equal "<script>alert(1)</script>", title_for("&lt;script&gt;alert(1)&lt;/script&gt;")
  end

  test "drops markup that arrives raw in a title" do
    assert_equal "alert(1)", title_for("<script>alert(1)</script>")
    assert_equal "", title_for("<img src=x onerror=alert(1)>")
  end

  test "leaves a stray angle bracket that is not markup" do
    assert_equal "Sigur <3 Ros", title_for("Sigur <3 Ros")
  end

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
