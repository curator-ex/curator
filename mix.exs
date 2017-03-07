defmodule Curator.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/curator-ex/curator"
  @maintainers [
    "Eric Sullivan",
  ]

  def project do
    [
      app: :curator,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      description: "An Authentication and User Lifecycle Framework for Phoenix",
      package: package(),
      source_url: @url,
      homepage_url: @url,
      dialyzer: [plt_add_deps: :project],
    ]
  end

  def application do
    [applications: [:logger, :timex, :timex_ecto, :tzdata]]
  end

  defp deps do
    [
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ecto, "~> 2.0"},
      {:guardian, "~> 0.14"},
      {:phoenix, "~> 1.2.1"},
      {:plug, "~> 1.2"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
    ]
  end

  defp package do
    [
      name: :curator,
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
    ]
  end
end
