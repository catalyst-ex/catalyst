defmodule Catalyst.Actions.Function do
  alias Catalyst.CLI

  defstruct [:module, :function, :args]

  @type t :: %__MODULE__{
          module: module() | nil,
          function: atom() | nil,
          args: [term()] | nil
        }

  def execute(%__MODULE__{module: mod, function: fun, args: args}) do
    CLI.info("Executing function: #{mod}.#{fun}(#{Enum.map_join(args || [], ", ", &inspect/1)})")
    apply(mod, fun, args || [])
  end
end
