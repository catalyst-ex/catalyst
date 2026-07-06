defmodule Utils.Cache do
  @moduledoc """
  Simple cache based on Nebulex.

  To use, include "Utils.Cache.Coherent" in the
  children in Application tree.
  """

  alias __MODULE__, as: C
  alias Nebulex.Adapters

  @app :savrr
  @default_ttl to_timeout(hour: 1)

  defmodule Coherent do
    @moduledoc false
    use Nebulex.Cache, otp_app: Module.get_attribute(C, :app), adapter: Adapters.Coherent
  end

  # Public API
  # ----------

  @doc """
  Takes a resolver function whose value is only cached if it
  returns an `{:ok, any()}` tuple
  """
  @spec resolve(atom, atom, Keyword.t(), function()) :: any
  def resolve(type, key, opts \\ [], resolver) when is_function(resolver, 0) do
    Coherent.transaction(fn ->
      case get(type, key) do
        nil ->
          with {:ok, result} <- resolver.() do
            put(type, key, result, opts)
            {:ok, result}
          end

        result ->
          {:ok, result}
      end
    end)
    |> unwrap
  end

  @doc """
  Caches any value returned by the resolver function.
  """
  @spec resolve!(atom, atom, Keyword.t(), function()) :: any
  def resolve!(type, key, opts \\ [], resolver) when is_function(resolver, 0) do
    Coherent.transaction(fn ->
      with nil <- get(type, key) do
        result = resolver.()
        :ok = put(type, key, result, opts)
        result
      end
    end)
    |> unwrap
  end

  @doc "Get an item from the cache"
  @spec get(atom, atom) :: any
  def get(type, key), do: Coherent.get(name(type, key)) |> unwrap

  @doc "Fetch item from the cache"
  @spec fetch(atom, atom) :: {:ok, any} | {:error, :not_found}
  def fetch(type, key) do
    case get(type, key) do
      nil -> {:error, :not_found}
      val -> {:ok, val}
    end
  end

  @doc "Put an item in the cache"
  @spec put(atom, atom, any, Keyword.t()) :: :ok
  def put(type, key, value, opts \\ []) do
    name = name(type, key)
    opts = Keyword.put_new(opts, :ttl, @default_ttl)

    Coherent.put(name, value, opts)
  end

  @doc "Delete an item from the cache"
  @spec delete(atom, atom) :: :ok
  def delete(type, key), do: Coherent.delete(name(type, key))

  @doc "Clear all cached items"
  @spec flush() :: {:ok, integer()}
  defdelegate flush, to: Coherent, as: :delete_all

  # Private Helpers
  # ---------------

  defp name(type, key), do: "#{type}:#{key}"

  defp unwrap({:ok, value}), do: value
  defp unwrap(value), do: value
end
