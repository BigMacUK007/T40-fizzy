module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def track_event(action, creator: Current.user, collection: self.collection, **particulars)
    if should_track_event?
      collection.events.create!(action: "#{eventable_prefix}_#{action}", creator:, collection:, eventable: self, particulars:)
    end
  end

  def event_was_created(event)
  end

  private
    def should_track_event?
      true
    end

    def eventable_prefix
      self.class.name.demodulize.underscore
    end
end
