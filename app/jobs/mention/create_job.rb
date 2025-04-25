class Mention::CreateJob < ApplicationJob
  def perform(record, mentioner:)
    record.create_mentions(mentioner:)
  end
end
