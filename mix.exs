defmodule Curator.Mixfile do
  use Mix.Project

  @version "0.2.1"
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
      deps: deps(),
      description: "An Authentication and User Lifecycle Framework for Phoenix",
      package: package(),
      source_url: @url,
      homepage_url: @url,
      docs: docs(),
      dialyzer: [plt_add_deps: :project],
      aliases: aliases(),
    ]
  end

  def application do
    [applications: [:logger, :timex, :timex_ecto, :tzdata, :guardian]]
  end

  defp deps do
    [
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ecto, "~> 2.0"},
      {:ex_doc, "~> 0.10", only: :dev},
      {:guardian, "~> 1.0"},
      {:phoenix, "~> 1.3"},
      {:plug, "~> 1.2"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
    ]
  end

  def docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      name: :curator,
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*", "CHANGELOG.md"],
    ]
  end

  defp aliases do
    ["publish": ["hex.publish", &git_tag/1]]
  end

  defp git_tag(_args) do
    System.cmd "git", ["tag", "v" <> Mix.Project.config[:version]]
    System.cmd "git", ["push", "--tags"]
  end
end
