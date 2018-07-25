class AdsController < ApplicationController
    ADMIN_PARAMS = Set.new(["poliprob", "maxpoliprob"])
    PUBLIC_ROUTES = Set.new(["show", "index", "states_and_districts", "persona", "homepage_stats"])

    before_action :authenticate_partner!, unless: ->(c){ PUBLIC_ROUTES.include?(action_name) && c.params.keys.none?{|param| ADMIN_PARAMS.include?(param) }} # only admin users can modify the political probability
    skip_before_action :verify_authenticity_token

    caches_action :index, expires_in: 5.minutes, :cache_path => Proc.new {|c|  (c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";")).force_encoding("ascii-8bit") }
    caches_action :by_advertisers, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :by_targets, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :by_segments, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_week_advertisers, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_week_targets, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_week_segments, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_month_advertisers, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_month_targets, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_month_segments, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :homepage_stats, expires_in: 60.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :states_and_districts, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :persona, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }

    def show
        # the frontend does not prevent us from requesting ads in languages other than en-US and de for the show endpoint.
        # so here we'll just refuse to return the JSON
        # unless it's en-US or de OR if you'er logged in.
        lang = http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ad = Ad.find_by(lang: ["en-US", "de-DE"], id: params[:id])
        if !ad
            ad = Ad.unscoped.find_by(id: params[:id])
            authenticate_partner! if ad
        end
        render json: ad.as_json(:except => [:suppressed])
    end

    CANDIDATE_PARAMS = Set.new(["states", "districts", "parties", "joined"]) 
    def index
        is_admin = false
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"

        ads = params.keys.any?{|key| CANDIDATE_PARAMS.include?(key)} ? Ad.joins(:candidate).where(lang: lang) : Ad.where(lang: lang) 

        if params[:poliprob] || params[:maxpoliprob] # order matters!
            ads = ads.unscope(:where).where(lang: lang)
            is_admin = true
        end
        if params[:poliprob]
            if params[:poliprob].to_i != 0 # show even suppressed or unclassified ads if poliprob is 0
                ads = ads.where("suppressed = false").where("political_probability > ?", params[:poliprob].to_f / 100)
            end
        end
        if params[:maxpoliprob] # order matters!
            ads = ads.where("suppressed = false").where("political_probability < ?", params[:maxpoliprob].to_f / 100 )
        end


        if params[:search]
            # to_englishtsvector("ads"."html") @@ to_englishtsquery($4)
            ads = ads.where(lang[0..2] == "de" ? "to_germantsvector(html) @@ to_germantsquery(?)" : "to_englishtsvector(html) @@ to_englishtsquery(?)", params[:search]) 
        end

        # "advertisers=[\"Cathy+Myers\"]&targets=[{\"target\":\"Age\"}]&entities=[{\"entity\":\"Paul+Ryan\"}]"
        if params[:entities]
            ads = ads.where("entities @> ?", params[:entities])
        end
        if params[:targets]
            ads = ads.where("targets @> ?", params[:targets])
        end
        if params[:advertisers]
            ads = ads.where("advertiser in (?)", JSON.parse(params[:advertisers]))
        end
        if params[:states]
            states = params[:states].split(",")
            ads = ads.where(candidates: {state: states.size == 1 ? states[0] : states})
        end

        if params[:districts]
            states, districts = params[:districts].split(",").map{|dist| dist.split("-")}.transpose
            states.uniq!
            ads = ads.where(candidates: {
                district: districts.size == 1 ? districts[0] : district, 
                state: states.size == 1 ? states[0] : states
                })
        end

        if params[:parties]
            parties = Party.where(abbrev: params[:parties].split(","))
            ads = ads.where(candidates: {party: [parties.map(&:id).compact]})
        end

        page_num = [params[:page].to_i || 0, MAX_PAGE].min
        ads_page = ads.page((page_num.to_i || 0) + 1) # +1 here to mimic Rust behavior.

        resp = {}
        # .select(...) is a hotfix for SUPER SLOW latvian admin queries; I *suspect* because 'targetings' takes a long time to get out of the database.
        resp[:ads] = ads_page.select(:impressions, :paid_for_by, :targets, :html, :lang, :id, :created_at, :advertiser, :suppressed, :political_probability, :political, :not_political, :targeting, :title, :lower_page).as_json(:except => [:suppressed], include: params.keys.any?{|key| CANDIDATE_PARAMS.include?(key)} ? :candidate : nil )
        resp[:targets] = is_admin ? ads_page.map{|ad| (ad.targets || []).map{|t| t["target"]}}.flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.map{|k, v| {target: k, count: v} } : ads.unscope(:order).where("targets is not null").group("jsonb_array_elements(targets)->>'target'").order("count_all desc").limit(20).count.map{|k, v| {target: k, count: v} }
        resp[:entities] = is_admin ? [] : ads.unscope(:order).where("entities is not null").group("jsonb_array_elements(entities)->>'entity'").order("count_all desc").limit(20).count.map{|k, v| {entity: k, count: v} }
        resp[:advertisers] = is_admin ? (ads_page.map{|a| {"advertiser" => a.advertiser, "count" => 0}}.uniq) : ads.unscope(:order).where("advertiser is not null").group("advertiser").order("count_all desc").limit(20).count.map{|k, v| {advertiser: k, count: v} }
        resp[:total] = ads.count
        render json: resp
    end

    GENDERS_FB = ["men", "women"]
    MAX_PAGE = 50
    def persona
        lang = "en-US" # params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ads = params.keys.any?{|key| CANDIDATE_PARAMS.include?(key)} ? Ad.joins(:candidate).where(lang: lang) : Ad.where(lang: lang) 

        ads = ads.unscope(:order)
        ads = ads.order("(CURRENT_DATE - created_at) / sqrt(greatest(targetedness, 1)) asc " )

        raise(ActionController::BadRequest.new, "you've gotta specify at least one bucket") unless [:age_bucket, :politics_bucket, :location_bucket, :gender].any?{|bucket| params.include?(bucket) }

        age_bucket_for_puts = 
        if params[:age_bucket] && params[:age_bucket] != "--"
            age = [[params[:age_bucket].to_i, 65].min, 13].max

             ads = ads.where("not targets @> '[{\"target\": \"MinAge\"}]' OR " + Ad.send(:sanitize_sql_for_conditions, [
                (13..age).map{|_| "targets @> ?"}.join(" or ")
            ] + (13..age).map{|seg| "[{\"target\": \"MinAge\", \"segment\": \"#{seg}\"}]" } ))
                .where("not targets @> '[{\"target\": \"MaxAge\"}]' OR " + Ad.send(:sanitize_sql_for_conditions, [
                (age..65).map{|_| "targets @> ?"}.join(" or ")
            ] + (age..65).map{|seg| "[{\"target\": \"MaxAge\", \"segment\": \"#{seg}\"}]" } ))
            age_bucket_for_puts = "age: #{age}"
        else
            age_bucket_for_puts = "age: none"
        end
        if params[:location_bucket]
            # US ads,
            # state: location[0]
            # region: location[0]
            # state: location[0] && city: location[1]
            state, city = params[:location_bucket].split(",")
            if state != "any state"
                ads = ads.where("targets @> '[{\"target\": \"State\", \"segment\": \"#{state}\"}]' OR targets @> '[{\"target\": \"Region\", \"segment\": \"#{state}\"}]' OR targets @> '[{\"target\": \"Region\", \"segment\": \"United States\"}]'")
                
                ads = ads.where("(not targets @> '[{\"target\": \"City\"}]' OR targets @> '[{\"target\": \"City\", \"segment\": \"#{city}\"}]')") if city
            end
            loc_bucket_for_puts = "loc: #{state}, city: #{city}"
        else
            loc_bucket_for_puts = "loc: none"
        end
        
        politics = params[:politics_bucket] == "neither liberal nor conservative" ? "apolitical" : params[:politics_bucket]
        if politics && POLITICAL_BUCKETS.include?(politics)
            # targets @> '[{"target":"Segment","segment":"US politics (conservative)"}]'
            ads = ads.where(

                # segments
                Ad.send(:sanitize_sql_for_conditions, [
                    POLITICAL_BUCKETS[politics][:segment].map{|_| "targets @> ?"}.join(" or ")
                ] + POLITICAL_BUCKETS[politics][:segment].map{|seg| "[{\"target\": \"Segment\", \"segment\": \"#{seg}\"}]" } ) +

                # interests
                " OR " + Ad.send(:sanitize_sql_for_conditions, [
                    POLITICAL_BUCKETS[politics][:interest].map{|seg| "targets @> ?"}.join(" or ")
                ] + POLITICAL_BUCKETS[politics][:interest].map{|seg| "[{\"target\": \"Interest\", \"segment\": \"#{seg}\"}]" } ) + 

                # non-politically-targeted ads
                # No interest and no segment list, like, etc.
                # Retargeting: recently near their business
                " OR (not targets @> '[{\"target\": \"Interest\"}]' AND not targets @> '[{\"target\": \"List\"}]' AND not targets @> '[{\"target\": \"Like\"}]' AND not targets @> '[{\"target\": \"Segment\"}]' AND not targets @> '[{\"target\": \"Website\"}]' AND not targets @> '[{\"target\": \"Agency\"}]'  AND not targets @> '[{\"target\": \"Engaged with Content\"}]' AND not targets @> '[{\"target\": \"Activity on the Facebook Family\"}]' AND not targets @> '[{\"target\": \"Retargeting\", \"segment\": \"people who may be similar to their customers\"}]' ) OR (targets @> '[{\"target\": \"Retargeting\", \"segment\": \"recently near their business\"}]')"        
            )
            pol_bucket_for_puts = "pol: #{politics}"
        else
            pol_bucket_for_puts = "pol: none"
        end

        gender_regularizer = {
            "man" => "men",
            "male" => "men",
            "female" => "women",
            "woman" => "women",
            "a man" => "men",
            "a woman" => "women",
            "any gender" => nil
        }
        gender = gender_regularizer[params[:gender]]
        if gender && GENDERS_FB.include?(gender)
            other_gender = (GENDERS_FB - [gender]).first
            ads = ads.where("not targets @> ?", "[{\"target\": \"Gender\", \"segment\": \"#{other_gender}\"}]")
            gdr_bucket_for_puts = "gdr: #{gender}"
        else
            grd_bucket_for_puts = "gdr: none"
        end

        puts "#{age_bucket_for_puts}, #{loc_bucket_for_puts}, #{pol_bucket_for_puts}, #{gdr_bucket_for_puts}"

        # race, we're not doing; 
        page_num = [params[:page].to_i || 0, MAX_PAGE].min
        ads_page = ads.page(page_num + 1).per(19)  # +1 here to mimic Rust behavior.
        resp = {}

        resp[:ads] = ads_page.as_json(:except => [:suppressed], include: params.keys.any?{|key| CANDIDATE_PARAMS.include?(key)} ? :candidate : nil )
        resp[:total] = ads.count
        render json: resp

    end

    def suppress
        Ad.unscoped.find_by(id: params[:id]).suppress!
        render text: "Ok"
    end

    # for admin summary stats
    def summarize
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"

        # count of ads in language in the past day (via grouped by day for the past week)
        # count of ads in language in the past week
        ads_by_day_this_week = Ad.where(lang: lang).unscope(:order).where("created_at > now() - interval '1 week' ").group("date(created_at)").count
        ads_today = ads_by_day_this_week[ads_by_day_this_week.keys.last]
        ads_this_week = ads_by_day_this_week.values.reduce(&:+)

        # count of ads in language total
        political_ads_count = Ad.where(lang: lang).count

        # last week's ratio of ads to political ads
        daily_political_ratio = Ad.unscoped.where(lang: lang).where("created_at > now() - interval '1 week' ").group("date(created_at)").select("count(*) as total, sum(CASE political_probability > 0.7 AND NOT suppressed WHEN true THEN 1 ELSE 0 END) as political, date(created_at) as date").map{|ad| [ad.date, ad.political.to_f / ad.total, ad.total]}

        # rolling weekly ratio of ads to political ads
        weekly_political_ratio = Ad.unscoped.where(lang: lang).where("created_at > now() - interval '2 months' ").group("extract(week from created_at), extract(year from created_at)").select("count(*) as total, sum(CASE political_probability > 0.7 AND NOT suppressed WHEN true THEN 1 ELSE 0 END) as political, extract(week from created_at) as week, extract(year from created_at) as year").sort_by{|ad| ad.year.to_s + ad.week.to_s }.sort_by{|ad| ad.year.to_s + ad.week.to_s }.map{|ad| [ad.week, ad.political.to_f / ad.total, ad.total]}
        # datetime of last received ad
        last_received_at = Ad.unscoped.where(lang: lang).order(:created_at).last.created_at

        render json: {
            ads_this_week: ads_this_week,
            ads_today: ads_today,
            total_political_ads: political_ads_count,
            daily_political_ratio: daily_political_ratio,
            weekly_political_ratio: weekly_political_ratio,
            last_received_at: last_received_at
        }
    end

    # for the homepage's Feltron-style summary
    HOMEPAGE_STATS_CACHE_PATH = lambda {|lang| "#{Rails.root}/tmp/homepage_stats-#{lang}.json"}
    def homepage_stats
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        render file: HOMEPAGE_STATS_CACHE_PATH.call(lang), content_type: "application/json", layout: false and return if File.exists?(HOMEPAGE_STATS_CACHE_PATH.call(lang)) && (Time.now - File.mtime(HOMEPAGE_STATS_CACHE_PATH.call(lang)) < 60 * 60 ) # just read it from disk if cached thingy exists and is less than 60 minutes old.
        stats = Ad.calculate_homepage_stats(lang)
        File.open(HOMEPAGE_STATS_CACHE_PATH.call(lang), 'w'){|f| f.write(JSON.dump(stats))}
        STDERR.puts "wrote to disk since the cache doesn't exist"
        render json: stats
    end

    def by_state
        # TODO, later: like candidates_by_state but also include ads targeting Region, State
    end

    def states_and_districts
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        country = lang.split("-")[1] || "US"
        states = State.where(country: "US")
        house_districts = ElectoralDistrict.where(country: "US", office: "H").group_by(&:state)
        state_races = ElectoralDistrict.where(country: "US").where("office != 'H' and office != 'S'").group_by(&:state)
        # just return a list of valid states (in this country) and electoral districts
        # not actually returning any ads (this is for the page that lists stufc)
        render json: {
            states: states,
            districts: house_districts,
            state_races: state_races
        }
    end


    def by_advertisers
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ads = Ad.where(lang: lang)
        render json: ads.unscope(:order).where("advertiser is not null").group("advertiser").order("count_all desc").count.map{|k, v| {advertiser: k, count: v} }
    end

    def by_targets
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ads = Ad.where(lang: lang)
        render json: ads.unscope(:order).where("targets is not null").group("jsonb_array_elements(targets)->>'target'").order("count_all desc").count.map{|k, v| {target: k, count: v} }
    end

    def by_segments
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        render json: Ad.connection.select_rows("select concat(target, ' → ', segment), count(*) as count from (select jsonb_array_elements(targets)->>'segment' as segment, jsonb_array_elements(targets)->>'target' as target from ads WHERE lang = $1 AND political_probability > 0.70 AND suppressed = false) q group by segment, target having count(*) > 2 order by count desc;", nil, [[nil, lang]]).map{|k, v| {segment: k, count: v} } 
    end

    def this_week_advertisers
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ads = Ad.where(lang: lang).where("created_at > NOW() - interval '1 week'")
        render json: ads.unscope(:order).where("advertiser is not null").group("advertiser").order("count_all desc").count.map{|k, v| {advertiser: k, count: v} }
    end

    def this_week_targets
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ads = Ad.where(lang: lang).where("created_at > NOW() - interval '1 week'")
        render json: ads.unscope(:order).where("targets is not null").group("jsonb_array_elements(targets)->>'target'").order("count_all desc").count.map{|k, v| {target: k, count: v} }
    end

    def this_week_segments
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        render json: Ad.connection.select_rows("select concat(target, ' → ', segment), count(*) as count from (select jsonb_array_elements(targets)->>'segment' as segment, jsonb_array_elements(targets)->>'target' as target from ads WHERE lang = $1 AND political_probability > 0.70 AND suppressed = false and created_at > NOW() - interval '1 week') q group by segment, target having count(*) > 2 order by count desc;", nil, [[nil, lang]]).map{|k, v| {segment: k, count: v} } 
    end


    def this_month_advertisers
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ads = Ad.where(lang: lang).where("created_at > NOW() - interval '1 month'")
        render json: ads.unscope(:order).where("advertiser is not null").group("advertiser").order("count_all desc").count.map{|k, v| {advertiser: k, count: v} }
    end

    def this_month_targets
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        ads = Ad.where(lang: lang).where("created_at > NOW() - interval '1 month'")
        render json: ads.unscope(:order).where("targets is not null").group("jsonb_array_elements(targets)->>'target'").order("count_all desc").count.map{|k, v| {target: k, count: v} }
    end

    def this_month_segments
        lang = params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US"
        render json: Ad.connection.select_rows("select concat(target, ' → ', segment), count(*) as count from (select jsonb_array_elements(targets)->>'segment' as segment, jsonb_array_elements(targets)->>'target' as target from ads WHERE lang = $1 AND political_probability > 0.70 AND suppressed = false and created_at > NOW() - interval '1 month') q group by segment, target having count(*) > 2 order by count desc;", nil, [[nil, lang]]).map{|k, v| {segment: k, count: v} } 
    end

    def top_advertising_methods
        raise "not yet implemented" if params[:lang] && paarams[:lang] != "en-US"
        segment_counts = Ad.connection.select_rows("select concat(target, ' → ', segment), count(*) as count from (select jsonb_array_elements(targets)->>'segment' as segment, jsonb_array_elements(targets)->>'target' as target from ads WHERE lang = $1 AND political_probability > 0.70 AND suppressed = false and created_at > now() - interval '1 month') q group by segment, target having count(*) > 2 order by count desc;", nil, [[nil, "en-US"]]).map{|k, v| {segment: k, count: v} }

        method_counts = segment_counts.reduce(Hash.new(0)) do |memo, segment_count|
            segment = segment_count[:segment]
            count = segment_count[:count].to_i
            next memo if segment == "Age → 18 and older"
            next memo if segment == "Region → the United States"
            method_, target = segment.split(" → ")
            next memo if method_ == "MinAge"
            next memo if method_ == "MaxAge"
            method_ = "Political Interests/Segments" if method_ == "Segment" && (POLITICAL_BUCKETS["liberal"][:segment].include?(target) || POLITICAL_BUCKETS["conservative"][:segment].include?(target) )
            method_ = "Political Interests/Segments" if method_ == "Interest" && (POLITICAL_BUCKETS["liberal"][:interest].include?(target) || POLITICAL_BUCKETS["conservative"][:interest].include?(target) )
            method_ = "Lookalike Audience" if method_ == "Retargeting" && target == "people who may be similar to their customers"
            method_ = "Near Their Business" if method_ == "Retargeting" && target == "recently near their business"
            method_ = "Custom Audience" if method_ == "List"
            method_ = "State" if method_ == "Region"
            memo[method_] += count
            memo
        end
        render json: Hash[*method_counts.to_a.sort_by{|a, b| -b}.flatten(1)]
    end

    POLITICAL_BUCKETS = {
    "liberal" => {
        segment: [ 
            "US politics (liberal)",  # segment
            "Likely to engage with political content (liberal)",  # segment
            "US politics (very liberal)",  # segment
        ],  
        interest: [
            "Democratic Party (United States)",
            "Bernie Sanders",
            "Barack Obama",
            "Environmentalism",
            "Planned Parenthood",
            "Elizabeth Warren",
            "The People For Bernie Sanders",
            "The Young Turks",
            "MoveOn.org",
            "NPR",
            "Feminism",
            "Black Lives Matter",
            "Social justice",
            "Kamala Harris",
            "Hillary Clinton",
            "The New York Times",
            "Woke Folks",
            "Left-wing politics",
            "Climate change",
            "DREAM Act",
            "EMILY's List",
            "Mother Jones (magazine)",
        ]
    },
    "apolitical" => {
        segment: [        
            "US politics (moderate)",
            "Likely to engage with political content (moderate)",
        ],
        interest: [
            "Politics and social issues",
            "Politics",
            "Education",
            "Community issues",
            "Higher education",
            "Charity and causes",
            "Nonprofit organization",
            "Current events",
            "Nature",
            "Natural environment",
            "Environmental science",
            "Federal government of the United States",
            "National Park Service",
            "Mountains",
            "Business",
            "Fitness and wellness",
            "Family",
            "Volunteering",
            "Health system",
            "Medicare (United States)",
            "Technology",
            "Teacher",
            "Local government",
            "Family and relationships",
            "Supreme Court of the United States",
            "Business and industry",
            "Health care"

        ]
    },
    "conservative" => {
        segment: [
            "Likely to engage with political content (conservative)",
            "US politics (conservative)",
            "US politics (very conservative)",
        ],
        interest: [
            "Republican Party (United States)",
            "Ted Cruz",
            "Donald Trump",
            "Fox News Channel",
            "National Rifle Association"
        ]
    }
    }
end