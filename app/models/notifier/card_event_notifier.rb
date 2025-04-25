class Notifier::CardEventNotifier < Notifier
  delegate :creator, to: :source
  delegate :watchers_and_subscribers, to: :card

  private
    def recipients
      case source.action
      when "card_assigned"
        source.assignees.excluding(source.collection.access_only_users)
      when "card_published"
        watchers_and_subscribers(include_only_watching: true).without(creator, *card.mentionees)
      when "comment_created"
        watchers_and_subscribers.without(creator, *source.eventable.mentionees)
      else
        watchers_and_subscribers.without(creator)
      end
    end

    def card
      source.eventable
    end
end
