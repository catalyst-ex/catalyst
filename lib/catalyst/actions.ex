defmodule Catalyst.Actions do
  @moduledoc """
  Defines the action type contract returned by plugins.

  Concrete action structs are defined in dedicated modules under
  `Catalyst.Actions.*` (one file per action).
  """

  @type t ::
          Catalyst.Actions.SystemCommand.t()
          | Catalyst.Actions.AddFile.t()
          | Catalyst.Actions.PatchFile.t()
          | Catalyst.Actions.AddDependency.t()
          | Catalyst.Actions.MixTask.t()
          | Catalyst.Actions.AppendFile.t()
          | Catalyst.Actions.AddAlias.t()
          | Catalyst.Actions.MoveFile.t()
          | Catalyst.Actions.DeleteFile.t()
          | Catalyst.Actions.Function.t()
          | Catalyst.Actions.AddConfig.t()
end
