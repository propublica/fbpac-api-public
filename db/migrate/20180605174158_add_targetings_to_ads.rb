class AddTargetingsToAds < ActiveRecord::Migration
  def change
    add_column :ads, :targetings, :text, array: true #, default: []
    Ad.unscoped.where("targeting is not null").update_all("targetings[1] = targeting")
    Ad.unscoped.where("targetings[1] is null and targetings is not null").update_all("targetings = null")
  end
end
