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
      compilers: Mix.compilers() ++ [:archive_deps],
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:sourceror, "~> 1.0"},
      {:ucwidth, "~> 0.2"}
    ]
  end

  defp aliases do
    [
      quality: ["format"]
    ]
  end

  defp elixirc_paths(:test), do: archive_paths() ++ ["test/support"]
  defp elixirc_paths(_env), do: archive_paths()

  # Mix archives only contain the current application's compiled modules. Compile
  # the engine as part of the CLI application so the archive owns its runtime.
  defp archive_paths do
    ["lib", Path.expand("../lib", __DIR__)]
  end

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

defmodule Mix.Tasks.Compile.ArchiveDeps do
  @moduledoc false
  use Mix.Task.Compiler

  @runtime_deps [:sourceror, :ucwidth]

  @impl true
  def run(_args) do
    compile_path = Mix.Project.compile_path()
    build_path = Mix.Project.build_path()

    Enum.each(@runtime_deps, fn dependency ->
      build_path
      |> Path.join("lib/#{dependency}/ebin/*.beam")
      |> Path.wildcard()
      |> Enum.each(&File.cp!(&1, Path.join(compile_path, Path.basename(&1))))
    end)

    {:ok, []}
  end
end
