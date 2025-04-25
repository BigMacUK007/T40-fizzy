module Card::Eventable
  extend ActiveSupport::Concern

  include ::Eventable

  included do
    before_create { self.last_active_at = Time.current }

    after_save :track_due_date_change, if: :saved_change_to_due_on?
    after_save :track_title_change, if: :saved_change_to_title?
  end

  def event_was_created(event)
    transaction do
      find_or_capture_event_summary.events << event
      touch(:last_active_at)
    end
  end

  private
    def should_track_event?
      published?
    end

    def find_or_capture_event_summary
      messages.last&.event_summary || capture(EventSummary.new).event_summary
    end

    def track_due_date_change
      if due_on.present?
        if due_on_before_last_save.nil?
          track_event("card_due_date_added", particulars: { due_date: due_on })
        else
          track_event("card_due_date_changed", particulars: { due_date: due_on })
        end
      elsif due_on_before_last_save.present?
        track_event("card_due_date_removed")
      end
    end

    def track_title_change
      if title_before_last_save.present?
        track_event "card_title_changed", particulars: { old_title: title_before_last_save, new_title: title }
      end
    end
end
