defmodule Catalyst.CLI.Registry do
  @moduledoc """
  Resolves Catalyst plugin names from configured registries.
  """

  @default_registry_url "https://raw.githubusercontent.com/catalyst-ex/catalyst-plugins/main/registry.json"

  defmodule Entry do
    @moduledoc false

    @enforce_keys [:name, :module]
    defstruct [
      :name,
      :module,
      :package,
      :requirement,
      :source
    ]
  end

  def default_registry_url, do: @default_registry_url

  def resolve(name, opts \\ []) when is_binary(name) do
    normalized = normalize_name(name)

    cond do
      module_name?(name) ->
        {:ok, direct_module_entry(name)}

      normalized == "" ->
        {:error, {:invalid_name, name}}

      true ->
        opts
        |> registry_sources()
        |> resolve_from_sources(normalized)
    end
  end

  def resolve_module(module, opts \\ [])

  def resolve_module(module, opts) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> resolve_module(opts)
  end

  def resolve_module(module, opts) when is_binary(module) do
    opts
    |> registry_sources()
    |> resolve_module_from_sources(module)
  end

  defp resolve_from_sources(sources, name) do
    Enum.reduce_while(sources, {:error, :not_found}, fn source, _acc ->
      case load_source(source) do
        {:ok, registry} ->
          case entry_from_registry(registry, lookup_names(name), source) do
            {:ok, entry} -> {:halt, {:ok, entry}}
            :error -> {:cont, {:error, :not_found}}
          end

        {:error, reason} ->
          {:cont, {:error, reason}}
      end
    end)
    |> case do
      {:error, :not_found} -> {:error, {:not_found, name}}
      result -> result
    end
  end

  defp resolve_module_from_sources(sources, module) do
    Enum.reduce_while(sources, {:error, :not_found}, fn source, _acc ->
      case load_source(source) do
        {:ok, registry} ->
          case entry_for_module(registry, module, source) do
            {:ok, entry} -> {:halt, {:ok, entry}}
            :error -> {:cont, {:error, :not_found}}
          end

        {:error, reason} ->
          {:cont, {:error, reason}}
      end
    end)
    |> case do
      {:error, :not_found} -> {:error, {:module_not_found, module}}
      result -> result
    end
  end

  defp registry_sources(opts) do
    case Keyword.get(opts, :registries) do
      nil -> configured_or_default_sources()
      sources -> List.wrap(sources)
    end
  end

  defp configured_or_default_sources do
    case configured_sources() do
      {:ok, sources} -> sources
      :error -> [@default_registry_url]
    end
  end

  defp configured_sources do
    [Path.expand(".catalyst.exs"), Path.expand("~/.catalyst/config.exs")]
    |> Enum.reduce({false, []}, fn path, {found?, sources} ->
      if File.exists?(path) do
        registries =
          path
          |> Code.eval_file()
          |> elem(0)
          |> Keyword.get(:registries, [])
          |> List.wrap()

        {true, sources ++ registries}
      else
        {found?, sources}
      end
    end)
    |> case do
      {true, sources} -> {:ok, sources}
      {false, []} -> :error
    end
  end

  defp load_source(%{} = registry), do: {:ok, registry}

  defp load_source(path) when is_binary(path) do
    cond do
      String.starts_with?(path, ["http://", "https://"]) ->
        fetch_json(path)

      File.exists?(path) ->
        path
        |> File.read!()
        |> decode_json(path)

      true ->
        {:error, {:registry_not_found, path}}
    end
  end

  defp fetch_json(url) do
    _ = Application.ensure_all_started(:inets)
    _ = Application.ensure_all_started(:ssl)

    case :httpc.request(:get, {String.to_charlist(url), []}, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, body}} -> decode_json(body, url)
      {:ok, {{_, status, _}, _headers, _body}} -> {:error, {:http_error, url, status}}
      {:error, reason} -> {:error, {:http_error, url, reason}}
    end
  end

  defp decode_json(body, source) do
    case JSON.decode(body) do
      {:ok, registry} -> {:ok, registry}
      {:error, error} -> {:error, {:invalid_registry_json, source, error}}
    end
  end

  defp entry_from_registry(
         %{
           "schema_version" => 1,
           "package" => package,
           "plugins" => plugins
         } = registry,
         names,
         source
       )
       when is_binary(package) and is_map(plugins) do
    case find_plugin(plugins, names) do
      nil -> :error
      {name, module} when is_binary(module) -> {:ok, build_entry(name, module, registry, source)}
      _invalid -> :error
    end
  end

  defp entry_from_registry(_registry, _names, _source), do: :error

  defp entry_for_module(
         %{
           "schema_version" => 1,
           "package" => package,
           "plugins" => plugins
         } = registry,
         module,
         source
       )
       when is_binary(package) and is_map(plugins) do
    case Enum.find(plugins, fn {_name, registered_module} -> registered_module == module end) do
      {name, ^module} -> {:ok, build_entry(name, module, registry, source)}
      nil -> :error
    end
  end

  defp entry_for_module(_registry, _module, _source), do: :error

  defp find_plugin(plugins, names) do
    names
    |> Enum.find_value(fn name ->
      case Map.fetch(plugins, name) do
        {:ok, module} -> {name, module}
        :error -> nil
      end
    end)
  end

  defp build_entry(name, module, registry, source) do
    %Entry{
      name: name,
      package: Map.fetch!(registry, "package"),
      module: module,
      requirement: Map.get(registry, "requirement"),
      source: source
    }
  end

  defp direct_module_entry(name) do
    %Entry{
      name: name,
      module: name,
      source: :module
    }
  end

  defp module_name?(name) do
    name
    |> String.split(".")
    |> Enum.all?(&(&1 =~ ~r/^[A-Z][A-Za-z0-9_]*$/))
  end

  defp normalize_name(name) do
    name
    |> String.trim()
    |> String.downcase()
    |> String.replace("_", "-")
  end

  defp lookup_names(normalized_name) do
    camelized_name =
      normalized_name
      |> String.replace("-", "_")
      |> Macro.camelize()

    [normalized_name, camelized_name]
    |> Enum.uniq()
  end
end
