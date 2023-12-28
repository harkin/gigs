class CreateEventsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.string :price
      t.string :link_to_buy_ticket
      t.integer :venue, null: false
      t.boolean :tickets_available
      t.date :date, null: false
      t.timestamps

      t.index :venue
    end
  end
end
