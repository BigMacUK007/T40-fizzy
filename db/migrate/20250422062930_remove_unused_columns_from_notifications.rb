class RemoveUnusedColumnsFromNotifications < ActiveRecord::Migration[8.1]
  def change
    remove_column :notifications, :event_id
    remove_column :notifications, :card_id
  end
end
