class Ad < ActiveRecord::Base
	default_scope { where("political_probability > 0.7 and suppressed = false").order("created_at desc") }
	paginates_per 20

	belongs_to :candidate, primary_key: 'facebook_url', foreign_key: 'lower_page'

    USERS_COUNT = 11079 # 7/18 gotta record it manually from the FF and Chrome stats pages.
                        # 7/25, 1510 ff + 9569 ch
    def self.calculate_homepage_stats(lang) # internal only!
        political_ads_count = Ad.where(lang: lang).count
        political_ads_today = Ad.where(lang: lang).unscope(:order).where("created_at AT TIME ZONE 'America/New_York' > now() - interval '1 day' ").count
        # weekly_political_ratio = Ad.unscoped.where(lang: lang).where("created_at > now() - interval '9 weeks' ").group("extract(week from created_at), extract(year from created_at)").select("count(*) as total, sum(CASE political_probability > 0.7 AND NOT suppressed WHEN true THEN 1 ELSE 0 END) as political, extract(week from created_at) as week, extract(year from created_at) as year").sort_by{|ad| ad.year.to_s + ad.week.to_s }.map{|ad| [ad.week, ad.political.to_f / ad.total, ad.total]}

        political_ads_per_day = Ad.unscope(:order).where(lang: lang).where("created_at AT TIME ZONE 'America/New_York' > (#{Rails.env.development? ? "'2018-06-28'::date" : "now()"} - interval '15 days') ").group("extract(doy from created_at AT TIME ZONE 'America/New_York'), extract(year from created_at AT TIME ZONE 'America/New_York')").select("count(*) as total, extract(doy from created_at AT TIME ZONE 'America/New_York') as doy, extract(year from created_at AT TIME ZONE 'America/New_York') as year").sort_by{|ad| ad.year.to_s + ad.doy.to_s }.map{|ad| [ad.doy, ad.total]}

		{
            user_count: USERS_COUNT,
            political_ads_total: political_ads_count, 
            political_ads_today: political_ads_today, 
            # weekly_political_ratio: weekly_political_ratio,
            political_ads_per_day: political_ads_per_day
        }
    end


	def suppress!
		self.suppressed = true
		self.save
	end

end