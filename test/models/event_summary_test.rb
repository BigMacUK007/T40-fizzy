require "test_helper"

class EventSummaryTest < ActiveSupport::TestCase
  test "body" do
    assert_equal " Assigned to JZ.", event_summaries(:logo_initial_activity).body
    assert_equal "Assigned to Kevin.", event_summaries(:logo_second_activity).body
  end
end
