defmodule Catalyst.Actions.MixTask do
  alias Catalyst.Execution
  alias Catalyst.Actions.SystemCommand

  defstruct [:name, :args, :env]

  def execute(%__MODULE__{name: task, args: args, env: env}, execution \\ Execution.new()) do
    cd =
      if task in ["new", "phx.new"] do
        nil
      else
        Execution.app_root(execution)
      end

    SystemCommand.execute(%SystemCommand{cmd: "mix", args: [task | args || []], env: env, cd: cd})
  end
end
