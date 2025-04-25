require "test_helper"

class MentionsTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "create mentions when creating messages" do
    assert_difference -> { Mention.count }, +1 do
      perform_enqueued_jobs only: Mention::CreateJob do
        collections(:writebook).cards.create title: "Cleanup", description: "Did you finish up with the cleanup, @david?"
      end
    end
  end

  test "mentionees are added as watchers of the card" do
    perform_enqueued_jobs only: Mention::CreateJob do
      card = collections(:writebook).cards.create title: "Cleanup", description: "Did you finish up with the cleanup @kevin?"
      assert card.watchers.include?(users(:kevin))
    end
  end
end
