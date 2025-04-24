class MakeEventsEventable < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :eventable, polymorphic: true, index: true

    execute <<~SQL
      update events set eventable_type = 'Card', eventable_id = card_id;
    SQL

    change_column_null :events, :eventable_id, false
    change_column_null :events, :eventable_type, false

    remove_reference :events, :card
  end
end
