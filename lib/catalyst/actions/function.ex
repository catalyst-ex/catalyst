defmodule Catalyst.Actions.Function do
  use Catalyst.Action

  alias Catalyst.CLI

  defstruct [:module, :function, :args]

  @impl true
  def run(%__MODULE__{module: mod, function: fun, args: args}, _execution) do
    CLI.info("Executing function: #{mod}.#{fun}(#{Enum.map_join(args || [], ", ", &inspect/1)})")
    apply(mod, fun, args || [])
  end
end
