defmodule Catalyst.Config do
  defstruct [:version, :app, :plugins, :__private__]

  defmodule App do
    defstruct [:name, :file, :module]
  end
end
