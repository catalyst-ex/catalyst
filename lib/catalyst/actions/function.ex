defmodule Catalyst.Actions.Function do
  alias Catalyst.CLI

  defstruct [:module, :function, :args]

  def execute(%__MODULE__{module: mod, function: fun, args: args}) do
    CLI.info("Executing function: #{mod}.#{fun}(#{Enum.map_join(args || [], ", ", &inspect/1)})")
    apply(mod, fun, args || [])
  end
end
