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
end
