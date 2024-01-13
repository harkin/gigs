class CreateRefreshTable < ActiveRecord::Migration[7.1]
  def change
    create_table :refreshes do |t|
      t.datetime :last_refresh_at, null: false
    end
  end
end
