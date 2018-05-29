require 'test_helper'

class AdsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "you can show a single ad" do
    get :show, id: ads(:enUSpolitical)
    assert_response :success
    body = JSON.parse(response.body)
    assert body["id"].to_s == "123456789001"
  end

  test "it returns ads in English" do 
    get :index
    assert_response :success

    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["lang"] == "en-US"}
  end
  test "it returns ads from Canada if you have the right headers" do 
    @request.headers["Accept-Language"] = "en-CA"
    get :index
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["lang"] == "en-CA"}
  end

  test "you can get ads in another language with ?lang param" do 
    get :index, {"lang" => "en-CA"}

    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["lang"] == "en-CA"}
  end
  test "it requires you to be logged in to get poliprob" do 
    get :index, {poliprob: 60}
    assert_response :redirect

    sign_in partners(:me)
    get :index, {poliprob: 60}
    assert_response :success
  end
  test "you can filter by poliprob and maxpoliprob" do 
    sign_in partners(:me)
    get :index, {"poliprob" => 0, "maxpoliprob" => 50}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["political_probability"].between?(0, 0.5)}
  end

  # http://localhost:3000/fbpac-api/ads?advertisers=%5B%22ACLU%22%5D
  # advertisers = ["ACLU"]
  test "you can filter by advertiser" do 
    get :index, {"advertisers" => '["Whatever"]'}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["advertiser"] == "Whatever"}
  end
  # http://localhost:3000/fbpac-api/ads?entities=%5B%7B%22entity%22%3A%22Donald+Trump%22%7D%5D
  # entities = [{"entity":"Donald+Trump"}]
  test "you can filter by entity" do 
    get :index, {"entities" => '[{"entity":"House"}]'}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["entities"].map{|h| h["entity"]}.include?("House")}
  end
  # http://localhost:3000/fbpac-api/ads?targets=%5B%7B%22target%22%3A%22Age%22%7D%5D
  # targets = [{"target":"Age"}]
  test "you can filter by target" do 
    get :index, {"targets" => '[{"target":"Region"}]'}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["targets"].map{|h| h["target"]}.include?("Region")}
  end

  test "you can filter by state" do 
    get :index, {"states" => 'NC,GA'}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ["NC", "GA"].include?(ad["candidate"]["state"])}
  end
  test "you can filter by party" do 
    get :index, {"parties" => "DEM,DFL"}
    right_answer_ids = ["DEM", "DFL"].map{|p| Party.find_by(abbrev: p).id.to_s}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| right_answer_ids.include?(ad["candidate"]["party"])}
  end
  test "you can filter by district" do 
    get :index, {"districts" => "GA-04"}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].all?{|ad| ad["candidate"]["state"] == "GA" && ad["candidate"]["district"] == "04"}
  end


  test "you can paginate" do 
    get :index
    assert_response :success
    bodyp0 = JSON.parse(response.body)

    get :index, {"page": 1}
    assert_response :success
    bodyp1 = JSON.parse(response.body)
    assert bodyp0["ads"] != bodyp1["ads"]
  end
  test "you can filter by advertiser, entity, target and page" do 
    get :index, {"advertisers" => '["Different"]', "entities" => '[{"entity":"Different"}]', "targets" => '[{"target":"Age"}]', "page": 1}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].size < 20 # checks that we're on the second page
  end
  test "you can filter by advertiser, entity, target, page and poliprob" do 
    sign_in partners(:me)
    get :index, {"poliprob": 0, "advertisers" => '["Different"]', "entities" => '[{"entity":"Different"}]', "targets" => '[{"target":"Age"}]', "page": 1}
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ads"].size >= 1
    assert body["ads"].size < 20 # checks that we're on the second page
  end

  test "you can't show a single ad with too low poliprob" do 
    get :show, id: ads(:enUSnonpolitical)
    assert_response :redirect
  end
  test "you can't show a single ad that's suppressed" do 
    get :show, id: ads(:enUSsuppressed)
    assert_response :redirect
  end
  test "you can get targets groupings -- iff you're logged in" do 
    sign_in partners(:me)
    get :by_segments
    assert_response :success
    body = JSON.parse(response.body)
    assert body.size >= 2
  end
  test "you can get segments groupings -- iff you're logged in" do 
    sign_in partners(:me)
    get :by_advertisers
    assert_response :success
    body = JSON.parse(response.body)
    assert body.size >= 2
  end
  test "you can get advertiser groupings -- iff you're logged in" do 
    sign_in partners(:me)
    get :by_targets
    assert_response :success
    body = JSON.parse(response.body)
    assert body.size >= 2
  end

  test "you can't get targets groupings -- if you're not logged in" do 
    get :by_segments
    assert_response :redirect
  end
  test "you can't get segments groupings -- if you're not logged in" do 
    get :by_advertisers
    assert_response :redirect
  end
  test "you can't get advertiser groupings -- if you're not logged in" do 
    get :by_targets
    assert_response :redirect
  end

  test "you can get states and districts" do 
    get :states_and_districts
    assert_response :success
    body = JSON.parse(response.body)
    body["states"].map(&:abbrev).all?{|abbrev| abbrev.match /[A-Z]{2}/}
    body["districts"].keys.first.match /[A-Z]{2}/
  end


end


