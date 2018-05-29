class AddLowerPageIndexToAds < ActiveRecord::Migration
  def change
  	add_index :ads, :lower_page, name: "ads_lower_page_idx"
  end
end
