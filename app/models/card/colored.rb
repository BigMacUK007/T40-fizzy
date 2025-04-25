module Card::Colored
  extend ActiveSupport::Concern

  COLORS = %w[ #3b3633 #67695e #eb7a32 #bf7c2b #c09c6f #746b1e #2c6da8 #5d618f #663251 #ff63a8 ]
  DEFAULT_COLOR = "#2c6da8"

  def color
    color_from_stage || DEFAULT_COLOR
  end

  private
    def color_from_stage
      stage&.color&.presence if doing?
    end
end
