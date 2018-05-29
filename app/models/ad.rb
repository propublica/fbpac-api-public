class Ad < ActiveRecord::Base
	default_scope { where("political_probability > 0.7 and suppressed = false").order("created_at desc") }
	paginates_per 20

	belongs_to :candidate, primary_key: 'facebook_url', foreign_key: 'lower_page'

	def targetedness
		# TODO: combine count of targeting attributes with some measure of how targeted they are.
	end


	def suppress!
		self.suppressed = true
		self.save
	end

end