require "test_helper"

class Notifications::MarkAllReadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "show" do
    assert_changes -> { notifications(:logo_published_kevin).reload.read? }, from: false, to: true do
      assert_changes -> { notifications(:layout_commented_kevin).reload.read? }, from: false, to: true do
        post notifications_mark_all_read_url
      end
    end

    assert_response :success
  end
end
