defmodule Catalyst.Config do
  defstruct [:version, :mode, :app, :plugins]

  defmodule App do
    defstruct [:name, :path, :module]
  end
end
