class LongerLinks < ActiveRecord::Migration[7.2]
  def change
    change_column(:events, :link_to_buy_ticket, :string, limit: 500)
  end
end
