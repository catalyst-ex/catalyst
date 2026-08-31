defmodule Mix.Tasks.Catalyst.Plugin do
  use Mix.Task

  alias Catalyst.CLI.IO

  @shortdoc "Installs or resolves a Catalyst plugin"

  @impl true
  def run(args) do
    case args do
      [name] ->
        IO.info("Resolving Catalyst plugin: #{name}")
        Mix.raise("Plugin registry support has not been implemented yet.")

      _ ->
        Mix.raise("Usage: mix catalyst.plugin <name>")
    end
  end
end
