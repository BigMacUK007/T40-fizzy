class Card::AutoCloseAllDueJob < ApplicationJob
  def perform
    ApplicationRecord.with_each_tenant do |tenant|
      Card.auto_close_all_due
    end
  end
end
