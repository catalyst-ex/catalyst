defmodule Catalyst.Execution do
  @moduledoc false

  alias Catalyst.Errors.ExecutionError

  defstruct [
    :config,
    plugin_runs: [],
    action_executions: []
  ]

  def new(opts \\ [])
  def new(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> new()

  def new(%{} = attrs) do
    %__MODULE__{
      config: Map.get(attrs, :config),
      plugin_runs: Map.get(attrs, :plugin_runs, []),
      action_executions: Map.get(attrs, :action_executions, [])
    }
  end

  def from_config(config) do
    new(%{
      config: config,
      plugin_runs: [],
      action_executions: []
    })
  end

  def record_plugin_run(%__MODULE__{} = execution, run) when is_map(run) do
    %{execution | plugin_runs: execution.plugin_runs ++ [run]}
  end

  def record_action_execution(%__MODULE__{} = execution, action_execution) do
    %{execution | action_executions: execution.action_executions ++ [action_execution]}
  end

  def mode(%__MODULE__{} = execution), do: fetch!(execution, [:mode], :missing_mode)

  def app_path(%__MODULE__{} = execution), do: fetch!(execution, [:app, :path], :missing_app_path)

  def app_name(%__MODULE__{} = execution), do: fetch!(execution, [:app, :name], :missing_app_name)

  def app_module(%__MODULE__{} = execution),
    do: fetch!(execution, [:app, :module], :missing_app_module)

  def otp_app(%__MODULE__{} = execution) do
    case fetch!(execution, [:app, :otp_app], :missing_otp_app) do
      otp_app when is_atom(otp_app) and not is_nil(otp_app) -> otp_app
      _ -> nil
    end
  end

  def app_root(%__MODULE__{} = execution) do
    Path.expand(app_path(execution) || ".")
  end

  def resolve_path(%__MODULE__{} = execution, path) do
    if Path.type(path) == :absolute do
      path
    else
      Path.join(app_root(execution), path)
    end
  end

  def mix_file(%__MODULE__{} = execution), do: resolve_path(execution, "mix.exs")

  def config_file(%__MODULE__{} = execution, file_name),
    do: resolve_path(execution, Path.join("config", file_name))

  defp fetch!(%__MODULE__{config: nil}, _path, _reason) do
    raise ExecutionError,
      reason: :missing_execution_config,
      context: %{}
  end

  defp fetch!(%__MODULE__{config: config}, path, reason) do
    value =
      Enum.reduce_while(path, config, fn key, current ->
        if is_map(current) do
          case Map.fetch(current, key) do
            {:ok, next} -> {:cont, next}
            :error -> {:halt, :missing}
          end
        else
          {:halt, :missing}
        end
      end)

    case value do
      :missing ->
        raise ExecutionError,
          reason: reason,
          context: %{path: path}

      nil ->
        raise ExecutionError,
          reason: reason,
          context: %{path: path}

      resolved ->
        resolved
    end
  end
end
