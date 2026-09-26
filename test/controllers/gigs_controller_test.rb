require "test_helper"

class GigsControllerTest < ActionDispatch::IntegrationTest
  def create_event(attributes = {})
    Event.create!({
      title: "Test Event",
      event_date: 1.week.from_now,
      ticket_status: :available,
      venue: :academy
    }.merge(attributes))
  end

  test "should get index" do
    get root_url
    assert_response :success
  end

  %w[table cards].each do |layout|
    test "#{layout} layout strips markup embedded in a scraped title" do
      create_event(title: "<img src=x onerror=alert(1)><script>alert(2)</script>")

      get root_url(layout: layout)

      assert_response :success
      assert_not_includes response.body, "onerror"
      assert_not_includes response.body, "alert(2)</script>"
    end

    test "#{layout} layout escapes entity-encoded markup in a scraped title" do
      create_event(title: "&lt;script&gt;alert(1)&lt;/script&gt;")

      get root_url(layout: layout)

      assert_response :success
      assert_not_includes response.body, "<script>alert(1)</script>"
      assert_includes response.body, "&lt;script&gt;alert(1)&lt;/script&gt;"
    end

    test "#{layout} layout renders entity-encoded titles as text" do
      create_event(title: "Bluey&#8217;s Big Play &amp; Friends")

      get root_url(layout: layout)

      assert_response :success
      assert_includes response.body, "Bluey’s Big Play &amp; Friends"
      assert_not_includes response.body, "&#8217;"
    end

    test "#{layout} layout drops links with an unsafe scheme" do
      create_event(title: "Dodgy Link", link_to_buy_ticket: "javascript:alert(1)", more_info: "javascript:alert(2)")

      get root_url(layout: layout)

      assert_response :success
      assert_not_includes response.body, "javascript:"
    end

    test "#{layout} layout keeps ordinary ticket links" do
      create_event(title: "Good Link", link_to_buy_ticket: "https://dice.fm/event/abc")

      get root_url(layout: layout)

      assert_response :success
      assert_includes response.body, "https://dice.fm/event/abc"
    end

    test "#{layout} layout badges only recently announced events" do
      create_event(title: "Brand New Gig", first_seen_at: 2.days.ago)
      create_event(title: "Long Standing Gig", first_seen_at: 8.days.ago)

      get root_url(layout: layout)

      assert_response :success
      assert_select "[data-new='true']", 1
      assert_select "[data-new='false']", 1
      assert_select ".new-badge", 1
    end
  end
  test "redesign groups dated gigs by day and folds running shows into On now" do
    create_event(title: "Tonight Gig", event_date: Date.current.in_time_zone.change(hour: 20))
    create_event(title: "Next Week Gig", event_date: 1.week.from_now)
    create_event(title: "Long Run", event_date: 3.days.ago, end_date: 2.weeks.from_now)

    get redesign_url

    assert_response :success
    assert_select "section.day", 2
    assert_select "section.day .rel", text: "Tonight"
    assert_select ".on-now .row", 1
    assert_select ".on-now .row .title", text: "Long Run"
    assert_select "section.day .time", text: "20:00"
  end

  test "redesign strips markup and escapes encoded markup in scraped titles" do
    create_event(title: "<img src=x onerror=alert(1)><script>alert(2)</script>")
    create_event(title: "&lt;script&gt;alert(3)&lt;/script&gt;")

    get redesign_url

    assert_response :success
    assert_not_includes response.body, "onerror"
    assert_not_includes response.body, "alert(2)</script>"
    assert_not_includes response.body, "<script>alert(3)</script>"
  end

  test "redesign links rows only to safe URLs" do
    create_event(title: "Good Link", link_to_buy_ticket: "https://dice.fm/event/abc")
    create_event(title: "Dodgy Link", link_to_buy_ticket: "javascript:alert(1)", more_info: "javascript:alert(2)")

    get redesign_url

    assert_response :success
    assert_select "a.row[href='https://dice.fm/event/abc']", 1
    assert_select "div.row", 1
    assert_not_includes response.body, "javascript:"
  end

  test "redesign shows only the statuses worth flagging" do
    create_event(title: "Gone", ticket_status: :sold_out)
    create_event(title: "Nearly Gone", ticket_status: :limited_availability)
    create_event(title: "Plenty Left", ticket_status: :available)
    create_event(title: "No Idea", ticket_status: :unknown)

    get redesign_url

    assert_response :success
    assert_select ".status-d .status", 2
    assert_select ".row.is-sold", 1
    assert_select ".row.is-sold[data-sold='true']", 1
  end

  test "redesign badges only recently announced events" do
    create_event(title: "Brand New Gig", first_seen_at: 2.days.ago)
    create_event(title: "Long Standing Gig", first_seen_at: 8.days.ago)

    get redesign_url

    assert_response :success
    assert_select ".row[data-new='true'] .new", 1
    assert_select ".row[data-new='false']", 1
  end
end
