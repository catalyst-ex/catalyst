defmodule Catalyst.Actions.MixTask do
  alias Catalyst.Actions.SystemCommand

  defstruct [:name, :args, :env]

  @type t :: %__MODULE__{
          name: binary() | nil,
          args: [binary()] | nil,
          env: [{binary(), binary()}] | keyword(binary()) | nil
        }

  def execute(%__MODULE__{name: task, args: args, env: env}) do
    SystemCommand.execute(%SystemCommand{cmd: "mix", args: [task | args || []], env: env})
  end
end
