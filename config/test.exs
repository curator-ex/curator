use Mix.Config

config :logger, level: :warn

config :guardian, Guardian,
  issuer: "MyApp",
  ttl: {1, :days},
  verify_issuer: true,
  secret_key: "woiuerojksldkjoierwoiejrlskjdf"

config :curator, Curator, []

config :phoenix, :json_library, Jason
