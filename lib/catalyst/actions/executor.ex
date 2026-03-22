defmodule Catalyst.Actions.Executor do
  alias Catalyst.Actions
  alias Catalyst.CLI
  alias Catalyst.Execution

  def run(action), do: run(action, Execution.new())

  @doc """
  Dispatches the action to the correct handler.
  """
  def run(%Actions.SystemCommand{} = action, execution),
    do: Actions.SystemCommand.execute(action, execution)

  def run(%Actions.AddFile{} = action, execution), do: Actions.AddFile.execute(action, execution)
  def run(%Actions.MixTask{} = action, execution), do: Actions.MixTask.execute(action, execution)

  def run(%Actions.AppendFile{} = action, execution),
    do: Actions.AppendFile.execute(action, execution)

  def run(%Actions.AddAlias{} = action, execution),
    do: Actions.AddAlias.execute(action, execution)

  def run(%Actions.AddDependency{} = action, execution),
    do: Actions.AddDependency.execute(action, execution)

  def run(%Actions.DeleteFile{} = action, _execution), do: Actions.DeleteFile.execute(action)
  def run(%Actions.MoveFile{} = action, _execution), do: Actions.MoveFile.execute(action)
  def run(%Actions.Function{} = action, _execution), do: Actions.Function.execute(action)

  def run(%Actions.AddConfig{} = action, execution),
    do: Actions.AddConfig.execute(action, execution)

  def run(action, _execution) do
    CLI.warn("Unknown action encountered: #{inspect(action)}")
    {:error, :unknown_action}
  end
end
