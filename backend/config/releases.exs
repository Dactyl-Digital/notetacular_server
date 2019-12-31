import Config

secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
app_port = System.fetch_env!("APP_PORT")
app_hostname = System.fetch_env!("APP_HOSTNAME")
rds_db_name = System.fetch_env!("RDS_DB_NAME")
rds_username = System.fetch_env!("RDS_USERNAME")
rds_password = System.fetch_env!("RDS_PASSWORD")
rds_hostname = System.fetch_env!("RDS_HOSTNAME")
mailgun_key = System.fetch_env!("MAILGUN_KEY")
mailgun_domain = System.fetch_env!("MAILGUN_DOMAIN")

config :backend, BackendWeb.Endpoint,
  http: [:inet6, port: String.to_integer(app_port)],
  secret_key_base: secret_key_base

config :backend,
  app_port: app_port

config :backend,
  app_hostname: app_hostname

# NOTE: This key is necessary for being able
# to run migrations
config :backend, :ecto_repos, [Dbstore.Repo]

# WTF:
# Why is it that the repo.config IO.puts'd
# inside of /lib/release.ex migrate function
# outputs a pool_size of 10.... When it's configured
# to 20 here.
# TODO: Ensure that prod.exs config file isn't having
# an effect on that output... Just changed it to have
# a pool_size of 12
config :dbstore, Dbstore.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: rds_db_name,
  username: rds_username,
  password: rds_password,
  hostname: rds_hostname,
  pool_size: 20,
  show_sensitive_data_on_connection_error: true

# NOTE: THat fixed it...
# From reading the mailgun adapter's source code:
# https://github.com/thoughtbot/bamboo/blob/master/lib/bamboo/adapters/mailgun_adapter.ex
# This function constructs the final URI... This wasn't conveyed in the docs
# defp full_uri(config) do
#   config.base_uri <> "/" <> config.domain <> "/messages"
# end
# The necessary api endpoint to send email:
# Output -> https://api.mailgun.net/v3/mg.notastical.com/messages
config :backend, Backend.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: mailgun_key,
  domain: mailgun_domain,
  base_uri: "https://api.mailgun.net/v3"

# Configure your database
# config :demo, Demo.Repo,
#   username: db_user,
#   password: db_password,
#   database: "demo_prod",
#   hostname: db_host,
#   pool_size: 10
