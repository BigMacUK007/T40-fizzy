module Bubble::Colored
  extend ActiveSupport::Concern

  COLORS = %w[ #BF1B1B #ED3F1C #ED8008 #7C956B #266ec3 #3B3633 ]

  included do
    attribute :color, default: "#266ec3"
  end
end
