class AddCreatorToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_reference :notifications, :creator, null: true, foreign_key: { to_table: :users }

    execute <<~SQL
      UPDATE notifications
        SET creator_id = (
          SELECT events.creator_id
          FROM events
          WHERE events.id = notifications.source_id
            AND notifications.source_type = 'Event'
        )
        WHERE source_type = 'Event';
    SQL

    change_column_null :notifications, :creator_id, true
  end
end
