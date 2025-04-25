class MakeEventSummaryOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :events, :summary_id, true
  end
end
