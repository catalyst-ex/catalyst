defmodule Catalyst do
  alias Catalyst.{Action, Plugin}

  def build(config) do
    {raw_actions, post_validations} =
      Enum.reduce(config.plugins, {[], []}, fn {plugin_mod, opts},
                                               {actions_acc, validations_acc} ->
        full_opts =
          opts
          |> Keyword.merge(app_path: config.app.path)
          |> Keyword.merge(app_name: config.app.name)
          |> Keyword.merge(app_module: config.app.module)

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
