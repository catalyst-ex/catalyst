defmodule Mix.Tasks.Catalyst.Run do
  use Mix.Task

  alias Catalyst.CLI.{IO, PluginRuntime}
  alias Catalyst.Config.Loader
  alias Catalyst.Errors.CLIError
  alias Catalyst.Trace.Formatter

  @shortdoc "Creates a new app from a configuration file"

  def run(args) do
    case args do
      [config_path] ->
        generate_from_config(config_path, :execute)

      [config_path, "--explain"] ->
        generate_from_config(config_path, :explain)

      _ ->
        raise CLIError,
          reason: :invalid_cli_args,
          context: %{args: args}
    end
  end

  defp generate_from_config(path, mode) do
    IO.info("Loading configuration from #{path}...")

    config = Loader.load!(path)
    working_dir = File.cwd!()
    dependencies = PluginRuntime.dependencies(config.plugins)

    if dependencies == [] do
      run_config(config, mode)
    else
      PluginRuntime.run(path, working_dir, dependencies, mode)
    end
  end

  defp run_config(config, mode) do
    case config.mode do
      :existing ->
        IO.info("Running Catalyst on existing project #{config.app.name}...")
        ensure_existing_project!(config.app.path)

      :new ->
        IO.info("Starting Catalyst for #{config.app.name}...")
        ensure_new_project_target!(config.app.path)
    end

    {:ok, execution} = Catalyst.build(config, mode)

    case mode do
      :explain ->
        IO.info(Formatter.format(execution.traces))
        IO.info(Formatter.summary(execution.traces))

      _ ->
        IO.success("Done! Catalyst finished in #{Path.expand(config.app.path)}")
    end
  end

  # -- Helpers --

  defp ensure_existing_project!(path) do
    unless File.exists?(path) do
      raise CLIError,
        reason: :missing_existing_project,
        context: %{path: path}
    end

    mix_file = Path.join(path, "mix.exs")

    unless File.exists?(mix_file) do
      raise CLIError,
        reason: :invalid_existing_project,
        context: %{path: path, mix_file: mix_file}
    end
  end

  defp ensure_new_project_target!(path) do
    if File.exists?(path) do
      raise CLIError,
        reason: :target_path_exists,
        context: %{path: path}
    end
  end
end
