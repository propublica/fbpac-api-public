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


        # political_ads_per_day = Ad.unscope(:order).where(lang: lang).where("created_at AT TIME ZONE 'America/New_York' > (#{Rails.env.development? ? "'2018-06-28'::date" : "now()"} - interval '15 days') ").group("extract(doy from created_at AT TIME ZONE 'America/New_York'), extract(year from created_at AT TIME ZONE 'America/New_York')").select("count(*) as total, extract(doy from created_at AT TIME ZONE 'America/New_York') as doy, extract(year from created_at AT TIME ZONE 'America/New_York') as year").sort_by{|ad| ad.year.to_s + ad.doy.to_s }.map{|ad| [ad.doy, ad.total]}

        # political_ads_per_week = Ad.unscope(:order).where(lang: lang).where("created_at AT TIME ZONE 'America/New_York' > '2018-01-01' ").group("extract(week from created_at AT TIME ZONE 'America/New_York'), extract(year from created_at AT TIME ZONE 'America/New_York')").select("count(*) as total, extract(week from created_at AT TIME ZONE 'America/New_York') as week, extract(year from created_at AT TIME ZONE 'America/New_York') as year").sort_by{|ad| ad.year.to_s + ad.week.to_i.to_s.rjust(3, '0') }.map{|ad| [ad.week, ad.total]}[0...-1]

        starting_count = 14916
        # cumulative_political_ads_per_day = Ad.unscope(:order).where(lang: lang).where("created_at AT TIME ZONE 'America/New_York' > '2018-01-01' ").group("extract(doy from created_at AT TIME ZONE 'America/New_York'), extract(year from created_at AT TIME ZONE 'America/New_York')").select("count(*) as total, extract(doy from created_at AT TIME ZONE 'America/New_York') as doy, extract(year from created_at AT TIME ZONE 'America/New_York') as year").sort_by{|ad| ad.year.to_s + ad.doy.to_i.to_s.rjust(3, '0') }.reduce([]){|memo, ad| memo << [ad.doy, (memo.last ? memo.last[1] : starting_count) + ad.total]; memo}
        cumulative_political_ads_per_week = Ad.unscope(:order).where(lang: lang).where("created_at AT TIME ZONE 'America/New_York' > '2018-01-01' ").group("((extract(year from created_at AT TIME ZONE 'America/New_York') - 2018) * 52) + extract(week from created_at AT TIME ZONE 'America/New_York'), extract(year from created_at AT TIME ZONE 'America/New_York')").select("count(*) as total, ((extract(year from created_at AT TIME ZONE 'America/New_York') - 2018) * 52) + extract(week from created_at AT TIME ZONE 'America/New_York') as week, extract(year from created_at AT TIME ZONE 'America/New_York') as year").sort_by{|ad| ad.year.to_s + ad.week.to_i.to_s.rjust(3, '0') }.reduce([]){|memo, ad| memo << [ad.week, (memo.last ? memo.last[1] : starting_count) + ad.total]; memo}

        {
            user_count: USERS_COUNT,
            political_ads_total: political_ads_count, 
            political_ads_today: Rails.env.development? ? 123 : political_ads_today, 
            # weekly_political_ratio: weekly_political_ratio,
            political_ads_per_day: cumulative_political_ads_per_week
        }
    end

    def self.advertiser_report(advertiser)
      individual_methods = Ad.connection.execute("select target, segment, count(*) as count from (select jsonb_array_elements(targets)->>'segment' as segment, jsonb_array_elements(targets)->>'target' as target from ads WHERE lang = 'en-US' and  #{Ad.send(:sanitize_sql_for_conditions, ["ads.advertiser = ?", [advertiser]] )}) q  group by segment, target order by count desc").to_a
      combined_methods = Ad.unscope(:order).where(advertiser: advertiser).group(:targets).count.to_a.sort_by{|a, b| -b}
      {individual_methods: individual_methods, combined_methods: combined_methods}
    end

    def public_url 
        "https://projects.propublica.org/facebook-ads/ad/#{id}"
    end

    def embed
        %{
    <div class="facebook-pac-ad">
     <div class="ad">
      <div class="message">
        <div>#{html}</div>
      </div>
      <div class="ad-metadata">
        <a href="https://projects.propublica.org/facebook-ads/ad/#{id}" class="permalink">
          Permalink to this ad
        </a>
        <p>
          First seen:
          <time datetime="#{created_at.to_s}">
            #{created_at.strftime("%A, %B %d, %Y")}
          </time>
        </p>
      </div>
      <div class="targeting_info">
        <div class="targeting">
         <h3>Targeting Information</h3>
         #{targeting}
        </div>
      </div>
    </div></div> }.chomp.lstrip
    end

    def suppress!
        self.suppressed = true
        self.save
    end

end