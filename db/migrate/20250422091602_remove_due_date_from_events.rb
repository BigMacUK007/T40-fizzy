class RemoveDueDateFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :due_date
  end
end
