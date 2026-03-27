defmodule Catalyst.Actions do
  @moduledoc false

  @type t ::
          %Catalyst.Actions.SystemCommand{}
          | %Catalyst.Actions.AddFile{}
          | %Catalyst.Actions.PatchFile{}
          | %Catalyst.Actions.AddDependency{}
          | %Catalyst.Actions.MixTask{}
          | %Catalyst.Actions.AppendFile{}
          | %Catalyst.Actions.AddAlias{}
          | %Catalyst.Actions.MoveFile{}
          | %Catalyst.Actions.DeleteFile{}
          | %Catalyst.Actions.Function{}
          | %Catalyst.Actions.AddConfig{}

  # Returns a stable identity key for an action.
  # Keys are used to compare actions for dedupe/reuse across phases.
  def key(%Catalyst.Actions.MixTask{name: name, args: args}),
    do: {:mix_task, name, args || []}

  def key(%Catalyst.Actions.SystemCommand{cmd: cmd, args: args}),
    do: {:system_command, cmd, args || []}

  def key(%{__struct__: mod} = action), do: {mod, Map.from_struct(action)}

  def key(action), do: action
end
