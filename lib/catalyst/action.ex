defmodule Catalyst.Action do
  @moduledoc """
  Defines the contract for all actions returned by plugins.
  """

  defmodule SystemCommand, do: defstruct([:cmd, :args, :env, :cd])
  defmodule AddFile, do: defstruct([:path, :content, :template_path])
  defmodule PatchFile, do: defstruct([:path, :ops])
  defmodule AddDependency, do: defstruct([:name, :version, :target_file, :opts])
  defmodule MixTask, do: defstruct([:name, :args, :env])
  defmodule AppendFile, do: defstruct([:path, :content])
  defmodule AddAlias, do: defstruct([:key, :commands, :target_file])

  @type t ::
          %SystemCommand{}
          | %AddFile{}
          | %PatchFile{}
          | %AddDependency{}
          | %MixTask{}
          | %AppendFile{}
          | %AddAlias{}
end
