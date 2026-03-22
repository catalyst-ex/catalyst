defmodule Catalyst do
  alias Catalyst.Execution

  def build(config) do
    execution = Execution.from_config(config)

    {raw_actions, post_validations} =
      Enum.reduce(config.plugins, {[], []}, fn plugin_spec, {actions_acc, validations_acc} ->
        {plugin_mod, opts} = normalize_plugin_spec!(plugin_spec)

        plugin_actions = plugin_mod.run(execution, opts)

        {
          actions_acc ++ plugin_actions,
          validations_acc ++ [{plugin_mod, opts}]
        }
      end)

    struct_actions = Catalyst.Plugin.normalize_actions(raw_actions)

    execute_actions(struct_actions, execution)
    run_post_validations(post_validations, execution)
  end

  defp normalize_plugin_spec!({plugin_mod, opts}) when is_atom(plugin_mod) and is_list(opts),
    do: {plugin_mod, opts}

  defp normalize_plugin_spec!({plugin_mod}) when is_atom(plugin_mod), do: {plugin_mod, []}

  defp normalize_plugin_spec!(plugin_mod) when is_atom(plugin_mod), do: {plugin_mod, []}

  defp normalize_plugin_spec!(invalid) do
    raise ArgumentError,
          "Invalid plugin entry: #{inspect(invalid)}. Expected module, {module}, or {module, keyword_opts}."
  end

  defp execute_actions(actions, execution) do
    Enum.each(actions, &Catalyst.Actions.Executor.run(&1, execution))
  end

  defp run_post_validations(validations, execution) do
    Enum.each(validations, fn {plugin_mod, opts} ->
      case plugin_mod.post_validate(execution, opts) do
        :ok ->
          :ok

        {:error, reason} ->
          Mix.raise("Post-validation failed in #{inspect(plugin_mod)}: #{inspect(reason)}")
      end
    end)
  end
end
