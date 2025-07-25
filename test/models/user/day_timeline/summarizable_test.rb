require "test_helper"

class User::DayTimeline::SummarizableTest < ActiveSupport::TestCase
  include VcrTestHelper

  setup do
    @user = users(:david)

    freeze_timestamps

    Current.session = sessions(:david)
    @day = events(:logo_published).reload.created_at
    @day_timeline = @user.timeline_for(@day, filter: @user.filters.new)
  end

  test "summarize" do
    assert_not @day_timeline.summarized?
    assert @day_timeline.events.any?

    summary = assert_difference -> { Event::ActivitySummary.count }, +1 do
      @day_timeline.summarize
    end

    assert @day_timeline.summarized?

    assert_equal summary, @day_timeline.summary

    assert_no_difference -> { Event::ActivitySummary.count } do
      @day_timeline.summarize
    end
  end

  test "past events are summarizable" do
    unfreeze_time

    # Not summarizable in the future
    travel_to @day - 2.weeks
    assert_not @day_timeline.summarizable?

    # Summarizable in the past
    travel_to @day + 1.day
    assert @day_timeline.summarizable?
  end

  test "today events are summarizable" do
    unfreeze_time

    travel_to @day
    assert_not @day_timeline.summarizable?

    10.times.each do |index|
      cards(:logo).update! title: "Title change #{index} to track event"
    end

    # Summarizable in the past
    assert @day_timeline.summarizable?
  end
end
