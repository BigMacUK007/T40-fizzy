class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close(user: Current.user, reason: params[:reason])
    render_card_replacement
  end

  def destroy
    @card.reopen
    render_card_replacement
  end
end
