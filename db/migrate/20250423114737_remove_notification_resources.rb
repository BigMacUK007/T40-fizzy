class RemoveNotificationResources < ActiveRecord::Migration[8.1]
  def change
    remove_reference :notifications, :resource, polymorphic: true, index: true
  end
end
