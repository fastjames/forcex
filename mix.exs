defmodule Forcex.Mixfile do
  use Mix.Project

  @description """
    Elixir library for the Force.com / SalesForce / SFDC REST API
  """

  def project do
    [
      aliases: aliases(),
      app: :forcex,
      version: "0.8.3",
      elixir: "~> 1.5",
      name: "Forcex",
      description: @description,
      package: package(),
      # compilers: [:forcex] ++ Mix.compilers,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.post": :test,
        docs: :dev,
        "hex.docs": :dev
      ],
      dialyzer: [
        plt_add_deps: :transitive,
        ignore_warnings: ".dialyzer_ignore.exs",
        flags: [
          # "-Wunmatched_returns",
          # "-Wrace_conditions",
          # "-Wunderspecs",
          # "-Wunknown",
          # "-Woverspecs",
          # "-Wspecdiffs",
        ],
        plt_add_apps: [:mix]
      ],
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      extra_applications: [:logger, :ssl]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:httpoison, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:timex, "~> 2.0 or ~> 3.0"},
      {:erlsom, "~> 1.4"},
      {:excoveralls, "~> 0.5", only: :test},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 1.1", only: :dev, override: true},
      {:mox, "~> 1.0", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:html_entities, "~> 0.4"}
    ]
  end

  defp package do
    [
      maintainers: ["Jeff Weiss", "Matt Robinson"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/jeffweiss/forcex"}
    ]
  end

  defp aliases do
    [
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "deps.unlock --check-unused",
        "test --warnings-as-errors",
        "credo"
      ]
    ]
  end
end
