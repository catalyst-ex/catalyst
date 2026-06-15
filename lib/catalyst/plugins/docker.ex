defmodule Catalyst.Plugins.Docker do
  use Catalyst.Plugin
  alias Catalyst.Actions, as: Action

  @impl true
  def run(_execution, _opts \\ []) do
    [
      {Action.RequirePlugin, plugin: Catalyst.Plugins.PhoenixBase, error: "Phoenix plugin is required"},
      {Action.AddFile,
        path: "ops/Dockerfile", content: File.read!(template_path("Dockerfile"))},
    ]
  end

  # --- Template Helpers ---

  defp template_path(filename) do
    Application.app_dir(:catalyst, ["priv", "templates", "ops", filename])
  end
end
