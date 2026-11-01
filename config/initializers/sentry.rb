# Exceptions go to Better Stack's error tracking, which accepts the Sentry
# protocol. SENTRY_DSN is set in production only; without it the SDK sends
# nothing.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = %w[production]
  config.release = ENV["KAMAL_VERSION"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  # Better Stack bills by exception. No traces, profiles or session counts.
  config.auto_session_tracking = false
  # No personal data: no signed-in user, cookies, request bodies, query
  # strings, SQL values or job arguments.
  config.data_collection.user_info = false
  config.data_collection.cookies = false
  config.data_collection.http_bodies = []
  config.data_collection.url_query_params = false
  config.data_collection.database_query_data = false
  config.data_collection.queues = false
end
