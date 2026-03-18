defmodule Catalyst.Actions do
  @moduledoc """
  Defines the action type contract returned by plugins.

  Concrete action structs are defined in dedicated modules under
  `Catalyst.Actions.*` (one file per action).
  """

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
end
