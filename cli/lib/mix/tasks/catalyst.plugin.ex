defmodule Mix.Tasks.Catalyst.Plugin do
  use Mix.Task

  alias Catalyst.CLI.{IO, Registry}

  @shortdoc "Installs or resolves a Catalyst plugin"

  @impl true
  def run(args) do
    case args do
      [name] ->
        IO.info("Resolving Catalyst plugin: #{name}")

        case Registry.resolve(name) do
          {:ok, entry} ->
            IO.success("Resolved #{entry.name} -> #{entry.module}")
            print_entry(entry)

          {:error, {:not_found, normalized_name}} ->
            Mix.raise("Could not find Catalyst plugin: #{normalized_name}")

          {:error, reason} ->
            Mix.raise("Could not resolve Catalyst plugin #{name}: #{inspect(reason)}")
        end

      _ ->
        Mix.raise("Usage: mix catalyst.plugin <name>")
    end
  end

  defp print_entry(entry) do
    if entry.package do
      IO.puts("package: #{entry.package}")
    end

    if entry.requirement do
      IO.puts("requirement: #{entry.requirement}")
    end

    IO.puts("module: #{entry.module}")
  end
end
