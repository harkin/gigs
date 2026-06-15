require "test_helper"

class DataGrabbers::TitleCleanerTest < ActiveSupport::TestCase
  def strip(title)
    DataGrabbers::TitleCleaner.strip_promoter(title)
  end

  test "drops a promoter lead-in" do
    assert_equal "Skullcrusher", strip("Singular Artists presents Skullcrusher")
  end

  test "matches presents regardless of case" do
    assert_equal "Genesis Owusu", strip("MCD PRODUCTIONS PRESENTS Genesis Owusu")
  end

  test "matches the 'present' and 'pres' variants" do
    assert_equal "DEAD PIONEERS", strip("U:mack & Foggy Notions present DEAD PIONEERS")
    assert_equal "Dave East", strip("Smorgasbord pres Dave East")
  end

  test "handles a colon after presents" do
    assert_equal "Weston Loney", strip("MCD Presents: Weston Loney")
  end

  test "leaves titles without a promoter untouched" do
    assert_equal "Trancelate", strip("Trancelate")
    assert_equal "girlfriend.", strip("girlfriend.")
    assert_equal "DISORDER – Indie & Alternative Clubnight", strip("DISORDER – Indie & Alternative Clubnight")
  end

  test "does not match 'pres' inside another word" do
    assert_equal "Express Yourself", strip("Express Yourself")
  end
end
