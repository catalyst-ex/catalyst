defmodule Catalyst.Config do
  defstruct [:version, :mode, :app, :plugins]

  defmodule App do
    defstruct [:name, :path, :module, :otp_app]
  end
end
