class AddFirstSeenAtToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :first_seen_at, :datetime
  end
end
