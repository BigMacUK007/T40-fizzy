class Cards::ImagesController < ApplicationController
  include CardScoped

  def destroy
    @card.image.purge_later
    render_card_replacement
  end
end
