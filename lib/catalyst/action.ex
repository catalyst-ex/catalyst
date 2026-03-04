defmodule Catalyst.Action do
  @moduledoc """
  Defines the contract for all actions returned by plugins.
  """

  # --- File Actions ---
  defmodule AddFile, do: defstruct([:path, :content, :template_path])
  defmodule AppendFile, do: defstruct([:path, :content])
  defmodule DeleteFile, do: defstruct([:path])
  defmodule MoveFile, do: defstruct([:from, :to])

  # --- Command Actions ---
  defmodule SystemCommand, do: defstruct([:cmd, :args, :env, :cd])

  # --- Mix Task Actions ---
  defmodule AddAlias, do: defstruct([:key, :commands, :target_file])
  defmodule AddDependency, do: defstruct([:name, :version, :target_file, :opts])
  defmodule MixTask, do: defstruct([:name, :args, :env])

  # --- Misc. Actions ---
  defmodule Function, do: defstruct([:module, :function, :args])
  defmodule PatchFile, do: defstruct([:path, :ops])
  defmodule AddConfig, do: defstruct([:target_file, :app, :module, :opts])

  @type t ::
          %SystemCommand{}
          | %AddFile{}
          | %PatchFile{}
          | %AddDependency{}
          | %MixTask{}
          | %AppendFile{}
          | %AddAlias{}
          | %MoveFile{}
          | %DeleteFile{}
          | %Function{}
          | %AddConfig{}
end
