defmodule Catalyst.ActionRunner do
  @moduledoc false

  alias Catalyst.ActionExecution
  alias Catalyst.Actions.Executor
  alias Catalyst.Execution

  def run(action_entries, execution) do
    action_entries
    |> Enum.reduce({execution, []}, fn %{
                                         action: action,
                                         plugin: plugin,
                                         phase: phase
                                       },
                                       {execution_acc, executed_actions} ->
      try do
        result = Executor.run(action, execution_acc)

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
