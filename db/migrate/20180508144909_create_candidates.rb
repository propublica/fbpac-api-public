class CreateCandidates < ActiveRecord::Migration
  def change
    create_table :candidates do |t|
      t.string :name
      t.string :facebook_url
      t.string :office
      t.string :state
      t.string :district
      t.string :party
      t.string :facebook_page_id
      t.string :country

      t.timestamps null: false
    end
  end
end
