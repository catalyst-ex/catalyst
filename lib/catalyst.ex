defmodule Catalyst do
  alias Catalyst.Actions.Executor
  alias Catalyst.CLI
  alias Catalyst.Error
  alias Catalyst.Execution
  alias Catalyst.ValidationAction

  def build(config) do
    execution = Execution.from_config(config)

    {actions, post_validations} =
      Enum.reduce(config.plugins, {[], []}, fn plugin_spec, {actions_acc, validations_acc} ->
        {plugin_mod, opts} = normalize_plugin_spec!(plugin_spec)

        plugin_actions = plugin_mod.run(execution, opts)

        validation_actions =
          plugin_mod.post_validate(execution, opts)
          |> Enum.map(fn
            %ValidationAction{action: %{__struct__: _}} = validation ->
              %{validation | plugins: [plugin_mod]}

            %ValidationAction{action: action} ->
              raise Error,
                code: :invalid_validation_action,
                reason: :invalid_action,
                context: %{plugin: plugin_mod, action: action}

            invalid ->
              raise Error,
                code: :invalid_post_validate_item,
                reason: :invalid_validation_item,
                context: %{plugin: plugin_mod, item: invalid}
          end)

        {
          actions_acc ++ plugin_actions,
          validations_acc ++ validation_actions
        }
      end)

    execute_actions(actions, execution)
    run_post_validations(post_validations, actions, execution)
  end

  defp normalize_plugin_spec!({plugin_mod, opts}) when is_atom(plugin_mod) and is_list(opts),
    do: {plugin_mod, opts}

  defp normalize_plugin_spec!({plugin_mod}) when is_atom(plugin_mod), do: {plugin_mod, []}

  defp normalize_plugin_spec!(plugin_mod) when is_atom(plugin_mod), do: {plugin_mod, []}

  defp normalize_plugin_spec!(invalid) do
    raise Error,
      code: :invalid_plugin_spec,
      reason: :invalid_plugin_entry,
      context: %{plugin_spec: invalid}
  end

  defp execute_actions(actions, execution) do
    Enum.each(actions, &Executor.run(&1, execution))
  end

  defp run_post_validations(validations, existing_actions, execution) do
    warnings =
      validations
      |> resolve_validation_actions(existing_actions)
      |> dedupe_validation_actions()
      |> execute_validation_actions(execution)

    maybe_print_validation_summary(warnings)
    :ok
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

  # Deduplicates validation actions by action_key/1 while preserving first-seen order.
  # If duplicates exist, keeps one entry and merges metadata:
  # required becomes true if any duplicate is required,
  # and plugins is unioned to preserve source.
  defp dedupe_validation_actions(validations) do
    {ordered, _index} =
      Enum.reduce(validations, {[], %{}}, fn validation, {ordered_acc, index_acc} ->
        key = action_key(validation.action)

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
    Enum.reduce(validations, [], fn validation, warnings ->
      case run_action(validation.action, execution) do
        :ok ->
          warnings

        {:error, reason} ->
          message = format_validation_failure(validation, reason)

          if validation.required do
            raise Error,
              code: :post_validation_failed,
              reason: :required_validation_failed,
              context: %{validation: validation, error: reason}
          else
            [message | warnings]
          end
      end
    end)
    |> Enum.reverse()
  end

  defp maybe_print_validation_summary([]), do: :ok

  defp maybe_print_validation_summary(warnings) do
    details = warnings |> Enum.map(&("- " <> &1)) |> Enum.join("\n\n")

    CLI.warn("Optional post-validations reported issues:\n\n#{details}")
  end

  defp run_action(action, execution) do
    try do
      Executor.run(action, execution)
      :ok
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp find_matching_action(action, existing_actions) do
    key = action_key(action)
    Enum.find(existing_actions, &(action_key(&1) == key))
  end

  defp action_key(%Catalyst.Actions.MixTask{name: name, args: args}),
    do: {:mix_task, name, args || []}

  defp action_key(%Catalyst.Actions.SystemCommand{cmd: cmd, args: args}),
    do: {:system_command, cmd, args || []}

  defp action_key(%{__struct__: mod} = action), do: {mod, Map.from_struct(action)}

  defp action_key(action), do: action

  defp format_validation_failure(%ValidationAction{} = validation, reason) do
    plugins =
      validation.plugins
      |> Enum.map(&inspect/1)
      |> Enum.join(", ")

    reason_message = to_string(reason)

    "Post-validation failed in #{plugins} for #{inspect(validation.action)}:\n\n#{reason_message}"
  end
end
