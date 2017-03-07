defmodule Curator.Mixfile do
  use Mix.Project

  def project do
    [app: :curator,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     dialyzer: [plt_add_deps: :project],
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :timex, :timex_ecto, :tzdata]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
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
end
