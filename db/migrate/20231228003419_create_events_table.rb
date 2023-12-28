class CreateEventsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.string :price
      t.string :link_to_buy_ticket
      t.string :more_info
      t.integer :ticket_status, null: false
      t.integer :venue, null: false
      t.datetime :event_date, null: false
      t.timestamps

      t.index :venue
    end
  end
end
