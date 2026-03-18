defmodule Catalyst.Actions.MixTask do
  alias Catalyst.Actions.SystemCommand

  defstruct [:name, :args, :env]

  def execute(%__MODULE__{name: task, args: args, env: env}) do
    SystemCommand.execute(%SystemCommand{cmd: "mix", args: [task | args || []], env: env})
  end
end
