class AddLowerPageColumnToAds < ActiveRecord::Migration
  def change
    add_column :ads, :lower_page, :string

    Ad.update_all("lower_page = lower(page)")
    # add_index :ads, :lower_page, name: :ads_lower_page_idx
  end

end
