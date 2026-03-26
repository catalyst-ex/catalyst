defmodule Catalyst.PluginPlanner do
  @moduledoc false

  alias Catalyst.Error
  alias Catalyst.Execution
  alias Catalyst.ValidationAction

  def collect(plugin_specs, execution) do
    plugin_specs
    |> Enum.reduce({execution, [], []}, fn plugin_spec,
                                           {execution_acc, actions_acc, validations_acc} ->
      {plugin_mod, opts} = normalize_plugin_spec!(plugin_spec)

      try do
        {plugin_actions, validation_actions} =
          collect_plugin_actions(plugin_mod, execution_acc, opts)

        execution_acc =
          Execution.record_plugin_run(execution_acc, %{
            plugin: plugin_mod,
            opts: opts,
            status: :ok,
            actions_count: length(plugin_actions),
            validations_count: length(validation_actions)
          })

        entries = Enum.map(plugin_actions, &%{action: &1, plugin: plugin_mod, phase: :run})

        {
          execution_acc,
          actions_acc ++ entries,
          validations_acc ++ validation_actions
        }
      rescue
        error ->
          plugin_run = %{
            plugin: plugin_mod,
            opts: opts,
            status: :error,
            actions_count: 0,
            validations_count: 0,
            error: Exception.message(error)
          }

          # Here we re-raise to preserve failure semantics while adding plugin context.
          # However later we can consider allowing plugins to report errors without necessarily
          # failing the entire run, which would change this behavior
          _ = Execution.record_plugin_run(execution_acc, plugin_run)
          reraise_with_plugin_failure(error, plugin_run)
      end
    end)
  end

  # -- Helpers --

  defp collect_plugin_actions(plugin_mod, execution, opts) do
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

    {plugin_actions, validation_actions}
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

  defp reraise_with_plugin_failure(%Error{} = error, plugin_run) do
    raise Error,
      code: error.code,
      reason: error.reason,
      message: error.message,
      context: Map.put(error.context || %{}, :plugin_run, plugin_run)
  end

  defp reraise_with_plugin_failure(error, plugin_run) do
    raise Error,
      code: :plugin_execution_failed,
      reason: :plugin_failed,
      context: %{plugin_run: plugin_run, error: Exception.message(error)}
  end
end
