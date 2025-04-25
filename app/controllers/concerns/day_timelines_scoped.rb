module DayTimelinesScoped
  extend ActiveSupport::Concern

  included do
    include FilterScoped

    before_action :restore_collections_filter_from_cookie
    before_action :set_day_timeline
    after_action :save_collections_filter_to_cookie
  end

  private
    def restore_collections_filter_from_cookie
      if params[:clear_filter]
        delete_collections_filter_cookie
      else
        set_collections_filter_from_cookie
      end
    end

    def delete_collections_filter_cookie
      cookies.delete(:collection_filter)
    end

    def set_collections_filter_from_cookie
      if cookies[:collection_filter].present? && @filter.collections.blank?
        @filter.collection_ids = cookies[:collection_filter].split(",")
      end
    end

    def save_collections_filter_to_cookie
      cookies[:collection_filter] = @filter.collection_ids.join(",")
    end

    def set_day_timeline
      @day_timeline = Current.user.timeline_for(day, filter: @filter)
    end

    def day
      if params[:day].present?
        Time.zone.parse(params[:day])
      else
        Time.current
      end
    rescue ArgumentError
      head :not_found
    end
end
