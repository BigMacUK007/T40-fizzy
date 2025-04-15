class RemoveAccountsJoinCodeIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :accounts, :join_code
  end
end
