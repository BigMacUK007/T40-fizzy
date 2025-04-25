class Card::AutoReconsiderAllStagnatedJob < ApplicationJob
  def perform
    ApplicationRecord.with_each_tenant do |tenant|
      Card.auto_reconsider_all_stagnated
    end
  end
end
