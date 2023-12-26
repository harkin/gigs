require "test_helper"

class GigsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get gigs_index_url
    assert_response :success
  end
end
