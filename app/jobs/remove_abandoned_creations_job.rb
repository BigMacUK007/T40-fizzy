class RemoveAbandonedCreationsJob < ApplicationJob
  def perform
    ApplicationRecord.with_each_tenant do |tenant|
      Card.remove_abandoned_creations
    end
  end
end
