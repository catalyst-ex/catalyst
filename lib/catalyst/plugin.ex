defmodule Catalyst.Plugin do
  @callback init(opts :: keyword(), config :: map()) :: {:ok, keyword()} | {:error, term()}
  @callback run(opts :: keyword()) :: [Catalyst.Action.t() | {module(), keyword()}]
  @callback post_validate(opts :: keyword()) :: :ok | {:error, term()}

  defmacro __using__(_) do
    quote do
      @behaviour Catalyst.Plugin
      # Allows generic usage of Action modules
      alias Catalyst.Action

      def init(opts, _), do: {:ok, opts}
      def post_validate(_), do: :ok
      defoverridable init: 2, post_validate: 1
    end
  end

  @doc """
  Normalizes a list of mixed Actions (Structs or Tuples) into pure Structs.
  """
  def normalize_actions(actions) do
    Enum.map(actions, fn
      %{__struct__: _} = action ->
        action

      # If it's a tuple {Action.SystemCommand, [cmd: "echo"]}, convert to struct
      {mod, opts} when is_atom(mod) and is_list(opts) ->
        struct!(mod, opts)
    end)
  end
end
