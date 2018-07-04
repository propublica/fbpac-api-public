class AddPaidForByToAds < ActiveRecord::Migration
  def change
    add_column :ads, :paid_for_by, :text
  end
end
