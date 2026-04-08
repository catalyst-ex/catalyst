defmodule Catalyst.Plugins.GithubCI do
  use Catalyst.Plugin
  alias Catalyst.Actions, as: Action

  @impl true
  def run(_execution, _opts \\ []) do
    [
      {Action.AddFile,
       path: ".github/workflows/ci.yml", content: File.read!(template_path("workflows/ci.yml"))},
      {Action.AddFile,
       path: ".github/actions/build/action.yml",
       content: File.read!(template_path("actions/build/action.yml"))},
      {Action.AddFile,
       path: ".github/pull_request_template.md",
       content: File.read!(template_path("pull_request_template.md"))}
    ]
  end

  # --- Template Helpers ---

  defp template_path(filename) do
    Application.app_dir(:catalyst, ["priv", "templates", "github", filename])
  end
end
