defmodule Catalyst.Actions.MixTask do
  use Catalyst.Action

  alias Catalyst.Execution
  alias Catalyst.Actions.SystemCommand

  @impl true
  def run(action, execution \\ Execution.new()) when is_list(action) do
    task = Keyword.fetch!(action, :name)
    args = Keyword.get(action, :args, [])
    env = Keyword.get(action, :env, [])

    # For "mix new" and "mix phx.new", we set cd to nil so mix uses the
    # shell’s current working dir. For all other tasks, we set cd to
    # the app root so mix runs in the context of the app.
    cd =
      if task in ["new", "phx.new"] do
        nil
      else
        Execution.app_root(execution)
      end

    SystemCommand.run(type: SystemCommand, cmd: "mix", args: [task | args], env: env, cd: cd)
  end
end
