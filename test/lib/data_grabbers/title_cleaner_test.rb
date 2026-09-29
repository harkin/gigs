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

  def clean(title)
    DataGrabbers::TitleCleaner.clean(title)
  end

  test "decodes entities from feeds that ship encoded titles" do
    assert_equal "Bluey’s Big Play", clean("Bluey&#8217;s Big Play")
    assert_equal "Metric, Broken Social Scene & Stars", clean("Metric, Broken Social Scene &amp; Stars")
  end

  test "collapses the runs of whitespace entities leave behind" do
    assert_equal "Troy Hawke: Never Stop", clean("Troy Hawke:&nbsp; Never Stop")
  end

  test "leaves already-decoded titles alone" do
    assert_equal "St. Paul & The Broken Bones", clean("St. Paul & The Broken Bones")
    assert_equal "Sigur <3 Ros", clean("Sigur <3 Ros")
  end

  test "drops raw markup and keeps encoded markup as inert text" do
    assert_equal "alert(1)", clean("<script>alert(1)</script>")
    assert_equal "", clean("<img src=x onerror=alert(1)>")
    assert_equal "<script>alert(1)</script>", clean("&lt;script&gt;alert(1)&lt;/script&gt;")
  end

  test "drops a sold-out marker from the title" do
    assert_equal "Gurriers Outstore Performance", clean("Gurriers Outstore Performance (SOLD OUT)")
    assert DataGrabbers::TitleCleaner.sold_out?("Gurriers Outstore Performance (Sold Out)")
    assert_not DataGrabbers::TitleCleaner.sold_out?("Sold Out Sessions")
  end

  test "title-cases only all-caps titles" do
    assert_equal "Westside Cowboy", clean("WESTSIDE COWBOY")
    assert_equal "An Bothar Abhaile", clean("AN BOTHAR ABHAILE")
    assert_equal "Whelan's Indie Club", clean("WHELAN'S INDIE CLUB")
    assert_equal "Tradition Now: Ispíní na hÉireann", clean("Tradition Now: Ispíní na hÉireann")
    assert_equal "CURVEBALL: Nova Dream", clean("CURVEBALL: Nova Dream")
  end

  test "keeps acronyms, initials and tokens with digits in all-caps titles" do
    assert_equal "U2BABY – The Reinvention", clean("U2BABY – THE REINVENTION")
    assert_equal "A.S. Fanning", clean("A.S. FANNING")
    assert_equal "Genitorturers \"Live + Lewd\" UK Tour", clean("GENITORTURERS \"LIVE + LEWD\" UK TOUR")
  end
end
