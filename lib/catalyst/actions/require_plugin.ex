defmodule Catalyst.Actions.RequirePlugin do
  use Catalyst.Action

  alias Catalyst.Execution
  alias Catalyst.Errors.ActionError

  @impl true
  def run(action, execution \\ Execution.new()) when is_list(action) do
    plugin = Keyword.fetch!(action, :plugin)
    error = Keyword.get(action, :error, "Missing required peer dependency")
    unless plugin_installed?(execution, plugin) do
      raise ActionError,
            message: error,
            reason: :missing_plugin_dependency,
            context: %{plugin: plugin}
    end
    :ok
  end

  defp plugin_installed?(execution, plugin), do: Enum.any?(execution.plugin_runs, &(&1.plugin == plugin))

end
