class AdsController < ApplicationController
    ADMIN_PARAMS = Set.new(["poliprob", "maxpoliprob"])
    PUBLIC_ROUTES = Set.new(["show", "index", "states_and_districts"])

    before_action :authenticate_partner!, unless: ->(c){ PUBLIC_ROUTES.include?(action_name) && c.params.keys.none?{|param| ADMIN_PARAMS.include?(param) }} # only admin users can modify the political probability
    skip_before_action :verify_authenticity_token

    caches_action :index, expires_in: 5.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :by_advertisers, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :by_targets, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :by_segments, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_week_advertisers, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_week_targets, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_week_segments, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_month_advertisers, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_month_targets, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }
    caches_action :this_month_segments, expires_in: 30.minutes, :cache_path => Proc.new {|c|  c.request.url + (params[:lang] || http_accept_language.user_preferred_languages.find{|lang| lang.match(/..-../)} || "en-US") + c.request.query_parameters.except("lang").to_a.sort_by{|a, b| a }.map{|a|a.join(",")}.join(";") }

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
        if params[:segments]
            ads = ads.where("segments @> ?", params[:segments])
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

        ads_page = ads.page((params[:page].to_i || 0) + 1)

        render json: {
            ads: ads_page.as_json(:except => [:suppressed], include: params.keys.any?{|key| CANDIDATE_PARAMS.include?(key)} ? :candidate : nil ), # +1 here to mimic Rust behavior.
            targets: is_admin ? ads_page.map{|ad| (ad.targets || []).map{|t| t["target"]}}.flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.map{|k, v| {target: k, count: v} } : ads.unscope(:order).where("targets is not null").group("jsonb_array_elements(targets)->>'target'").order("count_all desc").limit(20).count.map{|k, v| {target: k, count: v} },
            entities: is_admin ? [] : ads.unscope(:order).where("entities is not null").group("jsonb_array_elements(entities)->>'entity'").order("count_all desc").limit(20).count.map{|k, v| {entity: k, count: v} },
            advertisers: is_admin ? (ads_page.map{|a| {"advertiser" => a.advertiser, "count" => 0}}.uniq) : ads.unscope(:order).where("advertiser is not null").group("advertiser").order("count_all desc").limit(20).count.map{|k, v| {advertiser: k, count: v} },
            total: ads.count,
        } 

    end

    # SELECT count(*) as count, advertiser FROM "ads" WHERE "ads"."lang" = $1 AND "ads"."political_probability" > $2 AND "ads"."suppressed" = $3 AND created_at > NOW() - interval '1 month' AND advertiser IS NOT NULL GROUP BY advertiser ORDER BY count desc LIMIT $4 -- binds: ["en-US", 0.7, false, 1000]

    def suppress
        Ad.unscoped.find_by(id: params[:id]).suppress!
        render text: "Ok"
    end


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
        weekly_political_ratio = Ad.unscoped.where(lang: lang).where("created_at > now() - interval '2 months' ").group("extract(week from created_at)").select("count(*) as total, sum(CASE political_probability > 0.7 AND NOT suppressed WHEN true THEN 1 ELSE 0 END) as political, extract(week from created_at) as week").map{|ad| [ad.week, ad.political.to_f / ad.total, ad.total]}

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

end
