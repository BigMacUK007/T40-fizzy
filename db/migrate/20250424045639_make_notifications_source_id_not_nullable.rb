class MakeNotificationsSourceIdNotNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :notifications, :source_id, false
  end
end
