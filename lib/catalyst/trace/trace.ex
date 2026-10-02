defmodule Catalyst.Trace do
  alias Catalyst.Execution
  alias Catalyst.Errors
  alias Catalyst.Trace.Formatter
  alias Catalyst.CLI.IO

  @moduledoc false

  @types [
    :plugin,
    :action
  ]

  @phases [
    :planning,
    :execution,
    :post_validation
  ]

  @type type :: :plugin | :action
  @type status :: :started | :completed | :failed
  @type phase :: :planning | :execution | :post_validation

  @type t :: %__MODULE__{
          id: integer(),
          type: type(),
          name: module(),
          status: status(),
          phase: phase(),
          started_at: DateTime.t(),
          finished_at: DateTime.t() | nil,
          duration: float() | nil,
          metadata: map(),
          error: map() | nil
        }

  defstruct [
    :id,
    :type,
    :name,
    :status,
    :phase,
    :started_at,
    :finished_at,
    :duration,
    :metadata,
    :error
  ]

  @spec trace(
          Execution.t(),
          type(),
          module(),
          phase(),
          (Execution.t() -> {Execution.t(), term()}),
          keyword()
        ) :: {Execution.t(), term()}

  def trace(
        %Execution{} = execution,
        type,
        name,
        phase,
        fun,
        opts \\ []
      )
      when is_function(fun, 1) do
    validate_type!(type)
    validate_phase!(phase)

    {execution, trace_id} =
      start_trace(
        execution,
        Keyword.merge(opts,
          type: type,
          name: name,
          phase: phase
        )
      )

    trace = get_trace!(execution, trace_id)

    log_trace(execution, trace, :info)

    try do
      {execution, result} = fun.(execution)

      {execution, _trace_id} = finish_trace(execution, trace_id)
      trace = get_trace!(execution, trace_id)

      log_trace(execution, trace, :success)

      {execution, result}
    rescue
      error ->
        {execution, _trace_id} = fail_trace(execution, trace_id, error)
        trace = get_trace!(execution, trace_id)
        log_trace(execution, trace, :error)
        reraise error, __STACKTRACE__
    end
  end

  # Helpers

  @spec start_trace(Execution.t(), keyword()) :: {Execution.t(), integer()}
  defp start_trace(%Execution{} = execution, opts) do
    trace =
      struct(
        %__MODULE__{
          id: System.unique_integer([:positive]),
          status: :started,
          metadata: %{},
          started_at: DateTime.utc_now()
        },
        opts
      )

    execution = %{execution | traces: execution.traces ++ [trace]}

    {execution, trace.id}
  end

  @spec finish_trace(Execution.t(), integer()) :: {Execution.t(), integer()}
  defp finish_trace(%Execution{} = execution, trace_id) do
    finished_at = DateTime.utc_now()

    execution =
      update_trace(
        execution,
        trace_id,
        status: :completed,
        finished_at: finished_at
      )

    {execution, trace_id}
  end

  @spec fail_trace(Execution.t(), integer(), Exception.t()) ::
          {Execution.t(), integer()}
  defp fail_trace(%Execution{} = execution, trace_id, error) do
    finished_at = DateTime.utc_now()

    execution =
      update_trace(
        execution,
        trace_id,
        status: :failed,
        finished_at: finished_at,
        error: %{
          type: error.__struct__,
          message: Exception.message(error),
          reason: Map.get(error, :reason),
          context: Map.get(error, :context)
        }
      )

    {execution, trace_id}
  end

  @spec update_trace(Execution.t(), integer(), keyword()) :: Execution.t()
  defp update_trace(%Execution{} = execution, trace_id, opts) do
    trace = get_trace!(execution, trace_id)

    finished_at = Keyword.get(opts, :finished_at, DateTime.utc_now())

    duration =
      DateTime.diff(
        finished_at,
        trace.started_at,
        :millisecond
      )

    opts = Keyword.put(opts, :duration, duration)

    traces =
      Enum.map(execution.traces, fn current_trace ->
        if current_trace.id == trace_id do
          struct(current_trace, opts)
        else
          current_trace
        end
      end)

    %{execution | traces: traces}
  end

  @spec get_trace!(Execution.t(), integer()) :: t()
  defp get_trace!(%Execution{traces: traces}, trace_id),
    do: Enum.find(traces, &(&1.id == trace_id))

  defp validate_type!(type) when type in @types, do: :ok

  defp validate_type!(type) do
    raise Errors.Trace,
      reason: :invalid_type,
      context: %{
        type: type,
        expected: @types
      }
  end

  defp validate_phase!(phase) when phase in @phases, do: :ok

  defp validate_phase!(phase) do
    raise Errors.Trace,
      reason: :invalid_phase,
      context: %{
        phase: phase,
        expected: @phases
      }
  end

  defp log_trace(%Execution{mode: :execute}, trace, level) do
    message = Formatter.format(trace)

    case level do
      :info ->
        IO.info(message)

      :success ->
        IO.success(message)

      :error ->
        IO.error(message)
    end
  end

  defp log_trace(_execution, _trace, _level), do: :ok
end
