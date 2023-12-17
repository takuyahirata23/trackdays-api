import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :trackdays, TrackdaysWeb.Endpoint,
  url: [host: "motorcycle-trackdays.com", port: 443],
  # check_origin: [
  #   "//trackdays.gigalixirapp.com",
  #   "https://trackdays.gigalixirapp.com/",
  #   "//motorcycle-trackdays.com"
  # ],
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [rewrite_on: [:x_forwarded_proto]]

# Configures Swoosh API Client
config :swoosh, :api_client, Swoosh.ApiClient.Hackney

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
