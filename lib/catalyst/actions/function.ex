defmodule Catalyst.Actions.Function do
  use Catalyst.Action
  require Logger

  @impl true
  def run(action, _execution) when is_list(action) do
    mod = Keyword.fetch!(action, :module)
    fun = Keyword.fetch!(action, :function)
    args = Keyword.get(action, :args, [])

    Logger.info("Executing function: #{mod}.#{fun}(#{Enum.map_join(args, ", ", &inspect/1)})")
    apply(mod, fun, args)
  end
end
