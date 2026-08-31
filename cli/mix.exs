defmodule Catalyst.CLI.MixProject do
  use Mix.Project

  @app :catalyst_cli
  @name "Catalyst CLI"
  @version "1.0.0-beta.0"
  @github "https://github.com/catalyst-ex/catalyst"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.19",
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
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

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:catalyst, path: ".."},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      quality: ["format"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp description do
    "Global Mix tasks for Catalyst"
  end

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
