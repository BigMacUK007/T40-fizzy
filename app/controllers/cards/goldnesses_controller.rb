class Cards::GoldnessesController < ApplicationController
  include CardScoped

  def create
    @card.gild
    render_card_replacement
  end

  def destroy
    @card.ungild
    render_card_replacement
  end
end
