module EventsTimeline
  extend ActiveSupport::Concern

  include CollectionFilterable

  included do
    before_action :set_activity_day
  end

  private
    def set_activity_day
      @activity_day = if params[:day].present?
        Time.zone.parse(params[:day])
      else
        Time.zone.now
      end
    rescue ArgumentError
      raise ActionController::RoutingError
    end

    def events_for_activity_day
      Current.user.accessible_events.where(created_at: @activity_day.all_day)
        .group_by { |event| [ event.created_at.hour, helpers.event_column(event) ] }
        .map { |hour_col, events| [ hour_col, events.uniq { |e| e.id } ] }
    end

    def latest_event_before_activity_day
      Current.user.accessible_events.where(created_at: ...@activity_day.beginning_of_day).chronologically.last
    end
end
