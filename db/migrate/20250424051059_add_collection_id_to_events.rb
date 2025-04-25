class AddCollectionIdToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :collection, foreign_key: true, index: true

    execute <<~SQL
      UPDATE events
      SET collection_id = (
        SELECT cards.collection_id
        FROM cards
        WHERE cards.id = events.eventable_id
      )
      WHERE eventable_type = 'Card'#{' '}
    SQL

    change_column_null :events, :collection_id, false
  end
end
