require "test_helper"

class DataGrabbers::StoreTest < ActiveSupport::TestCase
  def event_attributes(title:, venue: :academy)
    { title: title, event_date: 1.week.from_now, ticket_status: :available, venue: venue }
  end

  test "swaps the venue's rows for the scraped ones" do
    Event.create!(event_attributes(title: "Stale Academy Gig"))

    DataGrabbers::Store.replace(:academy) { [event_attributes(title: "Fresh Academy Gig")] }

    assert_equal ["Fresh Academy Gig"], Event.where(venue: :academy).pluck(:title)
  end

  test "leaves other venues untouched" do
    Event.create!(event_attributes(title: "Whelans Gig", venue: :whelans))

    DataGrabbers::Store.replace(:academy) { [event_attributes(title: "Academy Gig")] }

    assert_equal ["Whelans Gig"], Event.where(venue: :whelans).pluck(:title)
  end

  test "keeps existing rows when the scrape fails validation" do
    Event.create!(event_attributes(title: "Good Academy Gig"))

    assert_raises(RuntimeError) { DataGrabbers::Store.replace(:academy) { [] } }

    assert_equal ["Good Academy Gig"], Event.where(venue: :academy).pluck(:title)
  end

  test "accepts an empty scrape when the venue allows zero" do
    Event.create!(event_attributes(title: "Off Season", venue: :marlay_park))

    DataGrabbers::Store.replace(:marlay_park, min_count: 0) { [] }

    assert_empty Event.where(venue: :marlay_park)
  end

  test "returns the events it stored" do
    stored = DataGrabbers::Store.replace(:academy) { [event_attributes(title: "Returned Gig")] }

    assert_equal ["Returned Gig"], stored.map { |event| event[:title] }
  end
end
