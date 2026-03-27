defmodule Mix.Tasks.Catalyst.New do
  use Mix.Task
  alias Catalyst.CLI
  alias Catalyst.Config.Loader
  alias Catalyst.Error

  @shortdoc "Creates a new app from a configuration file"

  def run(args) do
    case args do
      [config_path] ->
        generate_from_config(config_path)

      _ ->
        raise Error,
          code: :invalid_cli_args,
          reason: :usage,
          context: %{args: args}
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
    {:ok, _execution} = Catalyst.build(config)

    CLI.success("Done! Catalyst finished in #{Path.expand(config.app.path)}")
  end

  # -- Helpers --

  defp ensure_existing_project!(path) do
    unless File.exists?(path) do
      raise Error,
        code: :missing_existing_project,
        reason: :not_found,
        context: %{path: path}
    end

    mix_file = Path.join(path, "mix.exs")

    unless File.exists?(mix_file) do
      raise Error,
        code: :invalid_existing_project,
        reason: :missing_mix_file,
        context: %{path: path, mix_file: mix_file}
    end
  end

  defp ensure_new_project_target!(path) do
    if File.exists?(path) do
      raise Error,
        code: :target_path_exists,
        reason: :already_exists,
        context: %{path: path}
    end
  end
end
