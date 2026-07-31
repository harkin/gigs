class LongerMoreInfo < ActiveRecord::Migration[8.1]
  def change
    # Matches link_to_buy_ticket; several venues store the same URL in both.
    change_column(:events, :more_info, :string, limit: 500)
  end
end
