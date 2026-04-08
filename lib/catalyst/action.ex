defmodule Catalyst.Action do
  alias Catalyst.Execution

  @callback run(action :: keyword(), execution :: %Execution{}) :: term()

  defmacro __using__(_) do
    quote do
      @behaviour Catalyst.Action
    end
  end
end
