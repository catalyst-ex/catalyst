defmodule Catalyst.Trace.Formatter do
  @moduledoc """
  Format Catalyst traces into human-readable explanations.
  """

  alias Catalyst.Trace

  @doc """
  Formats a single trace.
  """
  @spec format(Trace.t()) :: String.t()
  def format(%Trace{} = trace) do
    format_trace(trace)
  end

  @doc """
  Formats a list of traces.
  """
  @spec format([Trace.t()]) :: [String.t()]
  def format(traces) when is_list(traces) do
    traces
    |> Enum.map(&format/1)
    |> Enum.join("\n")
  end

  @doc """
  Formats a summary of traces.
  """
  @spec summary([Trace.t()]) :: String.t()
  def summary(traces) when is_list(traces) do
    plugins = Enum.count(traces, &(&1.type == :plugin))
    actions = Enum.count(traces, &(&1.type == :action))
    failed = Enum.count(traces, &(&1.status == :failed))

    total_duration =
      traces
      |> Enum.map(&(&1.duration || 0))
      |> Enum.sum()

    """

    Execution Summary
    =================
    Plugins:         #{plugins}
    Actions:         #{actions}
    Total duration:  #{format_duration(total_duration)}
    Failed:          #{failed}
    """
  end

  # ---------------------------------------------------------------------------
  # Trace types
  # ---------------------------------------------------------------------------

  defp format_trace(%Trace{
         type: :plugin,
         name: name,
         phase: phase,
         status: status,
         duration: duration,
         metadata: metadata,
         error: error
       }) do
    """

    Plugin #{inspect(name)} #{format_status(status)}
    during #{inspect(phase)} in #{format_duration(duration)}.
    #{format_error(metadata)}
    #{format_error(error)}
    """
  end

  defp format_trace(%Trace{
         type: :action,
         name: name,
         phase: phase,
         status: status,
         duration: duration,
         metadata: metadata,
         error: error
       }) do
    """

    Action #{inspect(name)} #{format_status(status)}
    during #{inspect(phase)} in #{format_duration(duration)}.
    #{format_metadata(metadata)}
    #{format_error(error)}
    """
  end

  # ---------------------------------------------------------------------------
  # Generic trace
  # ---------------------------------------------------------------------------

  defp format_trace(%Trace{
         type: type,
         name: name,
         phase: phase,
         status: status,
         duration: duration,
         metadata: metadata,
         error: error
       }) do
    """

    #{format_type(type)} #{inspect(name)} #{format_status(status)}
    during #{inspect(phase)} in #{format_duration(duration)}.
    #{format_metadata(metadata)}
    #{format_error(error)}
    """
  end

  # ---------------------------------------------------------------------------
  # Formatting
  # ---------------------------------------------------------------------------

  defp format_type(:plugin), do: "Plugin"
  defp format_type(:action), do: "Action"

  defp format_status(:completed), do: "completed successfully"
  defp format_status(:failed), do: "failed"
  defp format_status(:started), do: "started"

  defp format_duration(nil), do: "an unknown duration"

  defp format_duration(duration) when duration < 1_000 do
    "#{duration}ms"
  end

  defp format_duration(duration) when duration < 60_000 do
    "#{Float.round(duration / 1_000, 2)}s"
  end

  defp format_duration(duration) do
    "#{Float.round(duration / 60_000, 2)}m"
  end

  defp format_metadata(nil), do: ""

  defp format_metadata(metadata) when map_size(metadata) == 0, do: ""

  defp format_metadata(metadata) when is_map(metadata) do
    metadata
    |> Enum.map(&format_metadata_entry/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp format_metadata(_), do: ""

  # Plugin/action options
  defp format_metadata_entry({:opts, opts}) when opts != [] do
    opts = Keyword.drop(opts, [:content, :anchor])
    "Options: #{inspect(opts)}"
  end

  # Actions can contain the plugins involved in validation/execution
  defp format_metadata_entry({:plugins, plugins}) when plugins != [] do
    "Plugins: #{inspect(plugins)}"
  end

  # Actions can specify required dependencies
  defp format_metadata_entry({:required, required}) when required != [] do
    "Required: #{inspect(required)}"
  end

  defp format_metadata_entry({_key, nil}), do: ""

  defp format_metadata_entry({_key, []}), do: ""

  defp format_metadata_entry({key, value}) do
    "#{String.capitalize(to_string(key))}: #{inspect(value)}"
  end

  defp format_error(nil), do: ""

  defp format_error(%{
         type: type,
         message: message,
         reason: reason,
         context: context
       }) do
    [
      "Error: #{inspect(type)}",
      "Message: #{message}",
      format_reason(reason),
      format_context(context)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp format_error(error) do
    "Error: #{inspect(error)}"
  end

  defp format_reason(nil), do: ""
  defp format_reason(reason), do: "Reason: #{inspect(reason)}"

  defp format_context(%{} = context) when map_size(context) == 0, do: ""
  defp format_context(context), do: "Context: #{inspect(context)}"
end
