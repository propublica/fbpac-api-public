class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:loggedin]

  if Rails.env.production?
    before_action :cache
  end
  def cache
    response.headers["Surrogate-Key"] = "fbpac-api"
    ### staging / passworded
    #response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate, private"
    #response.headers["Pragma"] = "no-cache"
    #response.headers["Expires"] = "Sun, 10 May 2015 00:00:00 GMT"
    ### live
    expires_in(48.hours, public: true, must_revalidate: true)
  end

  def redirect_to_8080 
    redirect_to "localhost:8080/facebook-ads/admin"
  end

  def heartbeat
    head :ok, content_type: "text/html"
  end

  def loggedin
      authenticate_partner!
      render json: nil
  end

  def after_sign_in_path_for(resource)
    Rails.env.development? ? "http://localhost:8080/facebook-ads/admin" : "/facebook-ads/admin"
  end


end
