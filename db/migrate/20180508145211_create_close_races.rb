class CreateCloseRaces < ActiveRecord::Migration
  def change
    create_table :close_races do |t|
      t.string :state
      t.integer :district
      t.string :country
      t.string :office
      t.boolean :interesting

      t.timestamps null: false
    end
  end
end
