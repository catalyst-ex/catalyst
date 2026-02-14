defmodule Catalyst.Config do
  defstruct [:version, :app, :plugins]

  defmodule App do
    defstruct [:name, :path, :module]
  end
end
