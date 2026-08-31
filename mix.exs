defmodule Catalyst.MixProject do
  use Mix.Project

  @app :catalyst
  @name "Catalyst"
  @version "1.0.0-beta.1"
  @github "https://github.com/catalyst-ex/#{@app}"

  def project do
    [
      # Project
      app: @app,
      version: @version,
      elixir: "~> 1.19",
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # ExDoc
      name: @name,
      source_url: @github,
      homepage_url: @github,
      docs: [
        main: @name,
        canonical: "https://hexdocs.pm/#{@app}",
        extras: ["README.md"]
      ]
    ]
  end

  # BEAM Application
  def application do
    [extra_applications: [:logger]]
  end

  # Dependencies
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:sourceror, "~> 1.0"},
      {:ucwidth, "~> 0.2"}
    ]
  end

  # Mix Aliases
  defp aliases do
    [
      quality: ["format", "credo", "sobelow --exit low"]
    ]
  end

  # Compilation Paths
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Package Description
  defp description do
    "Codemod, generation and scaffolding for Elixir"
  end

  # Package Information
  defp package do
    [
      name: @app,
      maintainers: ["Sheharyar Naseer", "Mudassar Ali", "Rana Tallal Ahmad"],
      licenses: ~w[MIT],
      files: ~w(mix.exs lib README.md),
      links: %{"GitHub" => @github}
    ]
  end
end
