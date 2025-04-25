require "test_helper"

class Cards::GoldnessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    assert_changes -> { cards(:text).reload.golden? }, from: false, to: true do
      post card_goldness_path(cards(:text)), as: :turbo_stream
      assert_card_container_rerendered(cards(:text))
    end
  end

  test "destroy" do
    assert_changes -> { cards(:logo).reload.golden? }, from: true, to: false do
      delete card_goldness_path(cards(:logo)), as: :turbo_stream
      assert_card_container_rerendered(cards(:logo))
    end
  end
end
