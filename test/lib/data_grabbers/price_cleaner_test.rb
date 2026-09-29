require "test_helper"

class DataGrabbers::PriceCleanerTest < ActiveSupport::TestCase
  def tidy(price)
    DataGrabbers::PriceCleaner.tidy(price)
  end

  test "tidies the common shapes" do
    assert_equal "€24.50", tidy("24.50")
    assert_equal "from €14.50", tidy("FROM €14.50")
    assert_equal "from €14.50", tidy("FROM  €14.50")
    assert_equal "from €21.85", tidy("From €21.85")
    assert_equal "€15", tidy("€15.00")
    assert_equal "from €20", tidy("FROM €20")
  end

  test "passes unusual shapes through" do
    assert_equal "Free", tidy("Free")
    assert_equal "€9.50 - €12", tidy("€9.50 - €12.00")
    assert_equal "€25 + bkng fee", tidy("€25.00 + bkng fee")
    assert_equal "€12,50", tidy("€12,50")
    assert_nil tidy(nil)
    assert_nil tidy(" ")
  end
end
