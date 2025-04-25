require "test_helper"

class Card::ColoredTest < ActiveSupport::TestCase
  test "use default color no stage" do
    assert_equal Card::DEFAULT_COLOR, cards(:logo).color
  end

  test "use default color not in doing stage" do
    assert_equal Card::DEFAULT_COLOR, cards(:text).color
  end

  test "infer color from stage when in doing stage" do
    cards(:text).engage
    assert_equal cards(:text).stage.color, cards(:text).color
  end
end
