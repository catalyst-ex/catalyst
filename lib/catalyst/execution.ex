defmodule Catalyst.Execution do
  @moduledoc false

  defstruct [:app_path, :app_name, :app_module, :otp_app, :mode]

  def new(opts \\ [])
  def new(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> new()

  def new(%{} = attrs) do
    %__MODULE__{
      app_path: Map.get(attrs, :app_path) || ".",
      app_name: Map.get(attrs, :app_name),
      app_module: Map.get(attrs, :app_module),
      otp_app: Map.get(attrs, :otp_app),
      mode: Map.get(attrs, :mode)
    }
  end

  def from_config(config) do
    new(%{
      app_path: config.app.path,
      app_name: config.app.name,
      app_module: config.app.module,
      otp_app: config.app.otp_app,
      mode: config.mode
    })
  end

  def app_root(%__MODULE__{app_path: path}) do
    Path.expand(path || ".")
  end

  def otp_app(%__MODULE__{otp_app: otp_app}) when is_atom(otp_app) and not is_nil(otp_app),
    do: otp_app

  def otp_app(%__MODULE__{}), do: nil

  def resolve_path(%__MODULE__{} = execution, path) do
    if Path.type(path) == :absolute do
      path
    else
      Path.join(app_root(execution), path)
    end
  end

  def mix_file(%__MODULE__{} = execution), do: resolve_path(execution, "mix.exs")

  def config_file(%__MODULE__{} = execution),
    do: resolve_path(execution, Path.join("config", "config.exs"))
end
