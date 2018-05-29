# This file is used by Rack-based servers to start the application.


require ::File.expand_path('../config/environment', __FILE__)
map FbpacApi::Application.config.try(:propub_url_root) || "/" do
  run FbpacApi::Application
end