defmodule Catalyst do
  alias Catalyst.{Action, Plugin}

  def build(config) do
    raw_actions =
      config.plugins
      |> Enum.flat_map(fn {plugin_mod, opts} ->
        full_opts = Keyword.merge(opts, app_path: config.app.file)
        full_opts = Keyword.merge(full_opts, app_name: config.app.name)

        {:ok, init_opts} = plugin_mod.init(full_opts, config)
        plugin_mod.run(init_opts)
      end)

    struct_actions = Plugin.normalize_actions(raw_actions)

    execute_actions(struct_actions)
  end

  defp execute_actions(actions) do
    Enum.each(actions, &Action.Executor.run/1)
  end
end
