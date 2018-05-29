class AddIndexForLangPoliprobSuppressed < ActiveRecord::Migration
  def change
  	add_index :ads, [:political_probability, :lang, :suppressed], name: :index_ads_on_political_probability_lang_and_suppressed
  end
end
