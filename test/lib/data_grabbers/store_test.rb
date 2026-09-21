require "test_helper"

class DataGrabbers::StoreTest < ActiveSupport::TestCase
  def event_attributes(title:, venue: :academy, more_info: "https://example.com/1", **overrides)
    { title: title, event_date: 1.week.from_now.change(usec: 0), ticket_status: :available,
      venue: venue, more_info: more_info }.merge(overrides)
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

  test "keeps first_seen_at when a gig is scraped again" do
    attributes = event_attributes(title: "Recurring Gig")
    DataGrabbers::Store.replace(:academy) { [attributes] }
    first_seen = Event.sole.first_seen_at

    travel 2.days do
      DataGrabbers::Store.replace(:academy) { [attributes] }
    end

    assert_equal 1, Event.count
    assert_equal first_seen.to_i, Event.sole.first_seen_at.to_i
  end

  test "updates a renamed gig in place rather than re-announcing it" do
    attributes = event_attributes(title: "Original Name")
    DataGrabbers::Store.replace(:academy) { [attributes] }
    first_seen = Event.sole.first_seen_at

    travel 2.days do
      DataGrabbers::Store.replace(:academy) { [attributes.merge(title: "Renamed")] }
    end

    assert_equal 1, Event.count
    assert_equal "Renamed", Event.sole.title
    assert_equal first_seen.to_i, Event.sole.first_seen_at.to_i
  end

  # A moved start time can't be told apart from a second performance on the same
  # day; splitting wrongly costs a stray badge, merging wrongly drops a real gig.
  test "re-announces a gig whose start time moves" do
    attributes = event_attributes(title: "Time TBC")
    DataGrabbers::Store.replace(:academy) { [attributes] }
    first_seen = Event.sole.first_seen_at

    travel 2.days do
      DataGrabbers::Store.replace(:academy) { [attributes.merge(event_date: attributes[:event_date] + 30.minutes)] }
    end

    assert_equal 1, Event.count
    assert_operator Event.sole.first_seen_at, :>, first_seen
  end

  test "stamps only a genuinely new gig with the current time" do
    first = event_attributes(title: "First Gig")
    second = event_attributes(title: "Second Gig", more_info: "https://example.com/2")

    DataGrabbers::Store.replace(:academy) { [first] }

    travel 2.days do
      DataGrabbers::Store.replace(:academy) { [first, second] }

      assert_equal ["Second Gig"], Event.where("first_seen_at > ?", 1.day.ago).pluck(:title)
    end
  end

  test "drops a gig that is no longer listed" do
    DataGrabbers::Store.replace(:academy) do
      [event_attributes(title: "Staying"), event_attributes(title: "Going", more_info: "https://example.com/2")]
    end

    DataGrabbers::Store.replace(:academy) { [event_attributes(title: "Staying")] }

    assert_equal ["Staying"], Event.where(venue: :academy).pluck(:title)
  end

  test "stamps both copies of a gig listed twice alike" do
    attributes = event_attributes(title: "Listed Twice")
    DataGrabbers::Store.replace(:academy) { [attributes, attributes] }
    first_seen = Event.pluck(:first_seen_at).map(&:to_i)

    travel 2.days do
      DataGrabbers::Store.replace(:academy) { [attributes, attributes] }
    end

    assert_equal 2, Event.count
    assert_equal first_seen, Event.pluck(:first_seen_at).map(&:to_i)
  end

  # This is what keeps the whole listing from badging after the deploy that
  # adds the column.
  test "leaves a row that predates first_seen_at unstamped" do
    attributes = event_attributes(title: "Already Listed")
    Event.create!(attributes)

    DataGrabbers::Store.replace(:academy) { [attributes] }

    assert_nil Event.sole.first_seen_at
  end

  test "returns the events it stored" do
    stored = DataGrabbers::Store.replace(:academy) { [event_attributes(title: "Returned Gig")] }

    assert_equal ["Returned Gig"], stored.map { |event| event[:title] }
  end
end
