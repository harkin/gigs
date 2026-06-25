class AddEndDateToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :end_date, :datetime
  end
end
