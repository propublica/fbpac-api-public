class XForwardedForLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    xforwardedfor = env["HTTP_X_FORWARDED_FOR"]
    Rails.logger.info "X-Forwarded-For: #{xforwardedfor}" if xforwardedfor
    @app.call(env)
  end
end

