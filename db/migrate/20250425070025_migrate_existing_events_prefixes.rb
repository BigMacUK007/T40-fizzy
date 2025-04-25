class MigrateExistingEventsPrefixes < ActiveRecord::Migration[8.1]
  def change
    execute <<-SQL
      UPDATE events
      SET
        action = CASE
          WHEN action = 'commented' THEN 'comment_created'
          ELSE 'card_' || action
        END,
        eventable_id = CASE
          WHEN action = 'commented' THEN json_extract(particulars, '$.comment_id')
          ELSE eventable_id
        END,
        eventable_type = CASE
          WHEN action = 'commented' THEN 'Comment'
          ELSE eventable_type
        END;
    SQL
  end
end
