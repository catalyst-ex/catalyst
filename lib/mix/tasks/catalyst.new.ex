defmodule Mix.Tasks.Catalyst.New do
  use Mix.Task
  alias Catalyst.CLI
  alias Catalyst.Config.Loader

  @shortdoc "Creates a new app from a configuration file"

  def run(args) do
    # Parse args
    case args do
      [config_path] ->
        generate_from_config(config_path)

      _ ->
        Mix.raise("Usage: mix catalyst.new <path/to/config.exs>")
    end
  end

  defp generate_from_config(path) do
    CLI.info("Loading configuration from #{path}...")

    # Load configuration
    config = Loader.load!(path)

    case config.mode do
      :existing ->
        CLI.info("Running Catalyst on existing project #{config.app.name}...")
        ensure_existing_project!(config.app.path)

      :new ->
        CLI.info("Starting Catalyst for #{config.app.name}...")
        ensure_new_project_target!(config.app.path)
    end

    # Build the app
    Catalyst.build(config)

    CLI.success("Done! Catalyst finished in #{Path.expand(config.app.path)}")
  end

  defp ensure_existing_project!(path) do
    unless File.exists?(path) do
      Mix.raise(
        "Directory #{path} does not exist. Set app.path to an existing project directory."
      )
    end

    mix_file = Path.join(path, "mix.exs")

    unless File.exists?(mix_file) do
      Mix.raise("Expected Mix project at #{path}, but #{mix_file} was not found.")
    end
  end

  defp ensure_new_project_target!(path) do
    if File.exists?(path) do
      Mix.raise(
        "Directory #{path} already exists. Set mode: :existing to run Catalyst on an existing app."
      )
    end
  end
end
