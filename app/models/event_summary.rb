class EventSummary < ApplicationRecord
  include Messageable

  has_many :events, -> { chronologically }, dependent: :delete_all, inverse_of: :summary

  # FIXME: Consider persisting the body and compute at write time.
  def body
    events.map { |event| summarize(event) }.join(" ")
  end

  private
    delegate :time_ago_in_words, to: "ApplicationController.helpers"

    def summarize(event)
      case event.action
      when "card_assigned"
        "Assigned to #{event.assignees.pluck(:name).to_sentence}."
      when "card_unassigned"
        "Unassigned from #{event.assignees.pluck(:name).to_sentence}."
      when "card_staged"
        "#{event.creator.name} moved this to '#{event.stage_name}'."
      when "card_closed"
        "Closed by #{ event.creator.name }"
      when "card_unstaged"
        "#{event.creator.name} removed this from '#{event.stage_name}'."
      when "card_due_date_added"
        "#{event.creator.name} set due date to #{event.particulars.dig('particulars', 'due_date').to_date.strftime('%B %-d')}."
      when "card_due_date_changed"
        "#{event.creator.name} changed due date to #{event.particulars.dig('particulars', 'due_date').to_date.strftime('%B %-d')}."
      when "card_due_date_removed"
        "#{event.creator.name} removed the date."
      when "card_title_changed"
        "#{event.creator.name} changed title from '#{event.particulars.dig('particulars', 'old_title')}' to '#{event.particulars.dig('particulars', 'new_title')}'."
      end
    end
end
