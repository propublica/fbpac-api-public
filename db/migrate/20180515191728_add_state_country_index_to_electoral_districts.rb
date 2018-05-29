
class AddStateCountryIndexToElectoralDistricts < ActiveRecord::Migration
  def change
  	add_index :electoral_districts, [:state, :country], name: :state_country_districts_idx
  end
end
