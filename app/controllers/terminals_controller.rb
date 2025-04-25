class TerminalsController < ApplicationController
  def show
    @events = Current.user.accessible_events.chronologically.reverse_order.limit(20)
  end

  def edit
    @filter = Current.user.filters.from_params params.permit(*Filter::PERMITTED_PARAMS)
  end
end
