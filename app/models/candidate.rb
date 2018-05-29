class Candidate < ActiveRecord::Base
	has_many :ads, primary_key: "facebook_url", foreign_key: "lower_page", inverse_of: :candidate
end
