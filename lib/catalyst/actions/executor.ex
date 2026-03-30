defmodule Catalyst.Actions.Executor do
  alias Catalyst.Actions
  alias Catalyst.CLI
  alias Catalyst.Execution
  alias Catalyst.Errors.ActionError

  def run(action), do: run(action, Execution.new())

  @doc """
  Dispatches the action to the correct handler.
  """
  def run(%Actions.SystemCommand{} = action, execution),
    do: Actions.SystemCommand.run(action, execution)

  def run(%Actions.AddFile{} = action, execution), do: Actions.AddFile.run(action, execution)
  def run(%Actions.MixTask{} = action, execution), do: Actions.MixTask.run(action, execution)

  def run(%Actions.AppendFile{} = action, execution),
    do: Actions.AppendFile.run(action, execution)

  def run(%Actions.AddAlias{} = action, execution),
    do: Actions.AddAlias.run(action, execution)

  def run(%Actions.AddDependency{} = action, execution),
    do: Actions.AddDependency.run(action, execution)

  def run(%Actions.DeleteFile{} = action, execution),
    do: Actions.DeleteFile.run(action, execution)

  def run(%Actions.MoveFile{} = action, execution), do: Actions.MoveFile.run(action, execution)
  def run(%Actions.Function{} = action, execution), do: Actions.Function.run(action, execution)

  def run(%Actions.AddConfig{} = action, execution),
    do: Actions.AddConfig.run(action, execution)

  def run(action, _execution) do
    CLI.warn("Unknown action encountered: #{inspect(action)}")

    raise ActionError,
      reason: :unknown_action,
      context: %{action: action}
  end
end
