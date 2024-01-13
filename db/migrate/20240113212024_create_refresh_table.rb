class CreateRefreshTable < ActiveRecord::Migration[7.1]
  def change
    create_table :refresh_tables do |t|
      t.datetime :last_refresh_at, null: false
      t.timestamps
    end
  end
end
