defmodule Catalyst.Plugin do
  alias Catalyst.Execution
  alias Catalyst.ValidationAction

  @callback init(opts :: keyword(), config :: map()) :: {:ok, keyword()} | {:error, term()}
  @callback run(execution :: %Execution{}, opts :: keyword()) :: [Catalyst.Actions.t()]
  @callback post_validate(execution :: %Execution{}, opts :: keyword()) :: [ValidationAction.t()]

  defmacro __using__(_) do
    quote do
      @behaviour Catalyst.Plugin
      # Allows generic usage of Action modules
      alias Catalyst.Actions

      def init(opts, _), do: {:ok, opts}
      def post_validate(_execution, _opts), do: []
      defoverridable init: 2, post_validate: 2
    end
  end
end
