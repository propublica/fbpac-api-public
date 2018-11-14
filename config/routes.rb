Rails.application.routes.draw do

  scope "/fbpac-api" do 
    devise_for :partners

    get "heartbeat" => "application#heartbeat"

    # root  :to => redirect('/index.html')
    # get '/admin',  :to => redirect('/admin.html')

    get "loggedin" => "application#loggedin"
    post "loggedin" => "application#loggedin"

    get "states_and_districts" => "ads#states_and_districts"

    resources :ads, only: [:show, :index] do 
      member do 
        put "suppress"
        get "embed"
      end

      collection do 
        get "persona"
        get "top_advertising_methods"
        get "summarize"
        get "homepage_stats"
        get "write_homepage_stats"
        get "by_segments"
        get "by_advertisers"
        get "by_targets"
        get "this_month_segments"
        get "this_month_advertisers"
        get "this_month_targets"
        get "this_week_segments"
        get "this_week_advertisers"
        get "this_week_targets"
        get "advertiser"
        get "by_state"
      end
    end
  end
end