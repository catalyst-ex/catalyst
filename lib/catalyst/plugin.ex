defmodule Catalyst.Plugin do
  alias Catalyst.Actions

  @callback init(opts :: keyword(), config :: map()) :: {:ok, keyword()} | {:error, term()}
  @callback run(opts :: keyword()) :: [Catalyst.Actions.t() | {module(), keyword()}]
  @callback post_validate(opts :: keyword()) :: :ok | {:error, term()}

  defmacro __using__(_) do
    quote do
      @behaviour Catalyst.Plugin
      # Allows generic usage of Action modules
      alias Catalyst.Actions

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

      # If it's a tuple {Actions.SystemCommand, [cmd: "echo"]}, convert to struct
      {mod, opts} when is_atom(mod) and is_list(opts) ->
        struct!(mod, opts)
    end)
  end

  @doc """
  Executes a system command action through the action executor.
  """
  def run_system_command(%Actions.SystemCommand{} = command) do
    try do
      Catalyst.Actions.Executor.run(command)
      :ok
    rescue
      error -> {:error, Exception.message(error)}
    end
  end
end
