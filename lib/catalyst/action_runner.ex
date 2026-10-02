defmodule Catalyst.ActionRunner do
  @moduledoc false

  alias Catalyst.ActionExecution
  alias Catalyst.Actions.Executor
  alias Catalyst.Execution
  alias Catalyst.Trace

  def run(action_entries, execution) do
    action_entries
    |> Enum.reduce({execution, []}, fn %{
                                         action: action,
                                         plugin: plugin,
                                         phase: phase
                                       },
                                       {execution_acc, executed_actions} ->
      try do
        {execution_acc, result} =
          Trace.trace(
            execution_acc,
            :action,
            elem(action, 0),
            :execution,
            fn %Execution{mode: mode} = execution ->
              case mode do
                :explain ->
                  {execution, []}

                _ ->
                  result = Executor.run(action, execution)
                  {execution, result}
              end
            end,
            metadata: %{
              opts: elem(action, 1),
              plugin: plugin
            }
          )

        action_execution =
          ActionExecution.new(%{
            action: action,
            plugin: plugin,
            phase: phase,
            required: nil,
            status: :ok,
            result: result,
            error: nil
          })

        {
          Execution.record_action_execution(execution_acc, action_execution),
          executed_actions ++ [action]
        }
      rescue
        error ->
          action_execution =
            ActionExecution.new(%{
              action: action,
              plugin: plugin,
              phase: phase,
              required: nil,
              status: :error,
              result: nil,
              error: Exception.message(error)
            })

          _ = Execution.record_action_execution(execution_acc, action_execution)
          reraise(error, __STACKTRACE__)
      end
    end)
  end
end
