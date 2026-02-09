defmodule Mix.Tasks.Catalyst.New do
  use Mix.Task
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
    IO.puts("Loading configuration from #{path}...")

    # Load configuration
    config = Loader.load!(path)

    IO.puts("Starting Catalyst for #{config.app.name}...")

    # Build the app
    Catalyst.build(config)

    IO.puts("Done! App ready in /#{config.app.file}")
  end
end
