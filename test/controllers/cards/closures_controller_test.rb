require "test_helper"

class Cards::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    card = cards(:logo)

    assert_changes -> { card.reload.closed? }, from: false, to: true do
      post card_closure_path(card, reason: "Scope too big")
      assert_card_container_rerendered(card)
    end

    assert_equal "Scope too big", card.closure.reason
  end

  test "destroy" do
    card = cards(:shipping)

    assert_changes -> { card.reload.closed? }, from: true, to: false do
      delete card_closure_path(card)
      assert_card_container_rerendered(card)
    end
  end
end
