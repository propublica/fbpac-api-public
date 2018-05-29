class CreateElectoralDistricts < ActiveRecord::Migration
  def change
    create_table :electoral_districts do |t|
      t.string :state
      t.string :name
      t.string :office
      t.string :country

      t.timestamps null: false
    end
  end
end
