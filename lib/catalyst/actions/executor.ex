defmodule Catalyst.Actions.Executor do
  alias Catalyst.CLI
  alias Catalyst.Execution
  alias Catalyst.Errors.ActionError

  def run(action), do: run(action, Execution.new())

  @doc """
  Dispatches the action to the correct handler.
  """
  def run({mod, opts}, execution) when is_atom(mod) and is_list(opts) do
    Code.ensure_loaded?(mod)

    if function_exported?(mod, :run, 2) do
      mod.run(opts, execution)
    else
      unknown_action!({mod, opts})
    end
  end

  def run(action, _execution), do: unknown_action!(action)

  defp unknown_action!(action) do
    CLI.warn("Unknown action encountered: #{inspect(action)}")

    raise ActionError,
      reason: :unknown_action,
      context: %{action: action}
  end
end
