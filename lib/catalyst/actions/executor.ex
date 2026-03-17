defmodule Catalyst.Actions.Executor do
  alias Catalyst.Actions
  alias Catalyst.CLI

  @doc """
  Dispatches the action to the correct handler.
  """
  def run(%Actions.SystemCommand{} = action), do: Actions.SystemCommand.execute(action)
  def run(%Actions.AddFile{} = action), do: Actions.AddFile.execute(action)
  def run(%Actions.MixTask{} = action), do: Actions.MixTask.execute(action)
  def run(%Actions.AppendFile{} = action), do: Actions.AppendFile.execute(action)
  def run(%Actions.AddAlias{} = action), do: Actions.AddAlias.execute(action)
  def run(%Actions.AddDependency{} = action), do: Actions.AddDependency.execute(action)
  def run(%Actions.DeleteFile{} = action), do: Actions.DeleteFile.execute(action)
  def run(%Actions.MoveFile{} = action), do: Actions.MoveFile.execute(action)
  def run(%Actions.Function{} = action), do: Actions.Function.execute(action)
  def run(%Actions.AddConfig{} = action), do: Actions.AddConfig.execute(action)

  def run(action) do
    CLI.warn("Unknown action encountered: #{inspect(action)}")
    {:error, :unknown_action}
  end
end
