worker_processes 2
working_directory "/web/"
listen 115
preload_app true

# rails 4.1 conf, per
# https://devcenter.heroku.com/articles/concurrency-and-database-connections
after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    config = ActiveRecord::Base.configurations[Rails.env] ||
                Rails.application.config.database_configuration[Rails.env]
    config['pool'] = ENV['DB_POOL'] || 5
    ActiveRecord::Base.establish_connection(config)
  end
end
