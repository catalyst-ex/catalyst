defmodule Catalyst do
  alias Catalyst.{Action, Plugin}

  def build(config) do
    {raw_actions, post_validations} =
      Enum.reduce(config.plugins, {[], []}, fn plugin_spec, {actions_acc, validations_acc} ->
        {plugin_mod, opts} = normalize_plugin_spec!(plugin_spec)

        full_opts =
          opts
          |> Keyword.merge(app_path: config.app.path)
          |> Keyword.merge(app_name: config.app.name)
          |> Keyword.merge(app_module: config.app.module)
          |> Keyword.merge(mode: config.mode)

        {:ok, init_opts} = plugin_mod.init(full_opts, config)

        plugin_actions = plugin_mod.run(init_opts)

        {
          actions_acc ++ plugin_actions,
          validations_acc ++ [{plugin_mod, init_opts}]
        }
      end)

    struct_actions = Plugin.normalize_actions(raw_actions)

    execute_actions(struct_actions)
    run_post_validations(post_validations)
  end

  defp normalize_plugin_spec!({plugin_mod, opts}) when is_atom(plugin_mod) and is_list(opts),
    do: {plugin_mod, opts}

  defp normalize_plugin_spec!({plugin_mod}) when is_atom(plugin_mod), do: {plugin_mod, []}

  defp normalize_plugin_spec!(plugin_mod) when is_atom(plugin_mod), do: {plugin_mod, []}

  defp normalize_plugin_spec!(invalid) do
    raise ArgumentError,
          "Invalid plugin entry: #{inspect(invalid)}. Expected module, {module}, or {module, keyword_opts}."
  end

  defp execute_actions(actions) do
    Enum.each(actions, &Action.Executor.run/1)
  end

  defp run_post_validations(validations) do
    Enum.each(validations, fn {plugin_mod, opts} ->
      case plugin_mod.post_validate(opts) do
        :ok ->
          :ok

        {:error, reason} ->
          Mix.raise("Post-validation failed in #{inspect(plugin_mod)}: #{inspect(reason)}")
      end
    end)
  end
end
