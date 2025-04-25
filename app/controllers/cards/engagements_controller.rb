class Cards::EngagementsController < ApplicationController
  include CardScoped

  def create
    @card.engage
    render_card_replacement
  end

  def destroy
    @card.reconsider
    render_card_replacement
  end
end
