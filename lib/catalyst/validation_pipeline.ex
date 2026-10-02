defmodule Catalyst.ValidationPipeline do
  @moduledoc false

  alias Catalyst.ActionExecution
  alias Catalyst.Actions
  alias Catalyst.Actions.Executor
  alias Catalyst.Execution
  alias Catalyst.Errors.ValidationError
  alias Catalyst.ValidationAction
  alias Catalyst.Trace

  def run(validations, existing_actions, execution) do
    validations
    |> resolve_validation_actions(existing_actions)
    |> dedupe_validation_actions()
    |> execute_validation_actions(execution)
  end

  defp resolve_validation_actions(validations, existing_actions) do
    Enum.map(validations, fn
      %ValidationAction{reuse_existing: true, action: action} = validation ->
        case find_matching_action(action, existing_actions) do
          nil -> validation
          matched_action -> %{validation | action: matched_action}
        end

      %ValidationAction{} = validation ->
        validation
    end)
  end

  defp dedupe_validation_actions(validations) do
    {ordered, _index} =
      Enum.reduce(validations, {[], %{}}, fn validation, {ordered_acc, index_acc} ->
        key = Actions.key(validation.action)

        case Map.fetch(index_acc, key) do
          {:ok, position} ->
            updated =
              List.update_at(ordered_acc, position, fn %ValidationAction{} = existing ->
                %{
                  existing
                | required: existing.required or validation.required,
                  plugins: Enum.uniq(existing.plugins ++ validation.plugins)
                }
              end)

            {updated, index_acc}

          :error ->
            {ordered_acc ++ [validation], Map.put(index_acc, key, length(ordered_acc))}
        end
      end)

    ordered
  end

  defp execute_validation_actions(validations, execution) do
    Enum.reduce(validations, {[], execution}, fn validation, {warnings, execution_acc} ->
      {action_mod, action_opts} = validation.action

      {execution_acc, result} =
        Trace.trace(
          execution_acc,
          :action,
          action_mod,
          :post_validation,
          fn %Execution{mode: mode} = execution ->
            case mode do
              :explain ->
                {execution, {:ok, []}}

              _ ->
                result = run_action(validation.action, execution)
                {execution, result}
            end
          end,
          metadata: %{
            validator: Keyword.get(action_opts, :function),
            plugins: validation.plugins,
            required: validation.required
          }
        )

      case result do
        {:ok, result} ->
          action_execution =
            ActionExecution.new(%{
              action: validation.action,
              plugin: nil,
              plugins: validation.plugins,
              phase: :post_validate,
              required: validation.required,
              status: :ok,
              result: result,
              error: nil
            })

          {warnings, Execution.record_action_execution(execution_acc, action_execution)}

        {:error, reason} ->
          message = format_validation_failure(validation, reason)

          action_execution =
            ActionExecution.new(%{
              action: validation.action,
              plugin: nil,
              plugins: validation.plugins,
              phase: :post_validate,
              required: validation.required,
              status: :error,
              result: nil,
              error: Exception.message(reason)
            })

          execution_acc = Execution.record_action_execution(execution_acc, action_execution)

          if validation.required do
            raise ValidationError,
                  reason: :post_validation_failed,
                  context: %{validation: validation, error: Exception.message(reason)}
          else
            {[message | warnings], execution_acc}
          end
      end
    end)
    |> then(fn {warnings, execution_acc} -> {Enum.reverse(warnings), execution_acc} end)
  end

  defp run_action(action, execution) do
    try do
      {:ok, Executor.run(action, execution)}
    rescue
      error -> {:error, error}
    end
  end

  defp find_matching_action(action, existing_actions) do
    key = Actions.key(action)
    Enum.find(existing_actions, &(Actions.key(&1) == key))
  end

  defp format_validation_failure(%ValidationAction{} = validation, reason) do
    plugins =
      validation.plugins
      |> Enum.map(&inspect/1)
      |> Enum.join(", ")

    reason_message = Exception.message(reason)

    "Post-validation failed in #{plugins} for #{inspect(validation.action)}:\n\n#{reason_message}"
  end
end
