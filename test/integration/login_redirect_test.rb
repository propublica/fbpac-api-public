require 'test_helper'

class LoginRedirectTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  # test "the truth" do
  #   assert true
  # end

  test "after log in, you get sent back to a URL with facebook-ads in it" do
    sign_in partners(:me)
    get "/fbpac-api/partners/sign_in"
    assert_redirected_to("/facebook-ads/admin")
  end

end
