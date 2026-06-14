require "test_helper"

class DataGrabbers::EventValidatorTest < ActiveSupport::TestCase
  def valid_event(**overrides)
    { title: "A Gig", event_date: 1.week.from_now.to_date, venue: :button_factory }.merge(overrides)
  end

  test "passes a well-formed batch" do
    assert_nothing_raised do
      DataGrabbers::EventValidator.validate!([valid_event, valid_event], venue: :button_factory)
    end
  end

  test "raises on an empty batch — the strongest drift signal" do
    error = assert_raises(RuntimeError) do
      DataGrabbers::EventValidator.validate!([], venue: :button_factory)
    end
    assert_match(/markup\/API likely changed/, error.message)
  end

  test "raises when below an explicit min_count" do
    assert_raises(RuntimeError) do
      DataGrabbers::EventValidator.validate!([valid_event], venue: :academy, min_count: 5)
    end
  end

  test "raises on a blank title (markup moved)" do
    assert_raises(RuntimeError) do
      DataGrabbers::EventValidator.validate!([valid_event(title: "  ")], venue: :academy)
    end
  end

  test "raises on a missing event_date" do
    assert_raises(RuntimeError) do
      DataGrabbers::EventValidator.validate!([valid_event(event_date: nil)], venue: :academy)
    end
  end

  test "raises on an implausibly far-future date (date parse broke)" do
    error = assert_raises(RuntimeError) do
      DataGrabbers::EventValidator.validate!([valid_event(event_date: 10.years.from_now.to_date)], venue: :academy)
    end
    assert_match(/implausible event_date/, error.message)
  end
end
