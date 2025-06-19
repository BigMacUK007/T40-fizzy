class Prompts::CardsController < ApplicationController
  def index
    @cards = if filter_param.present?
      Current.user.accessible_cards.mentioning(filter_param)
    else
      Current.user.accessible_cards.latest.limit(10)
    end
    render layout: false
  end

  private
    def filter_param
      params[:filter]
    end
end
