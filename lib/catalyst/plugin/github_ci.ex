defmodule Catalyst.Plugin.GithubCI do
  use Catalyst.Plugin
  alias Catalyst.Actions, as: Action

  @impl true
  def run(opts) do
    app_path = opts[:app_path]

    [
      %Action.AddFile{
        path: Path.join([app_path, ".github", "workflows", "ci.yml"]),
        content: File.read!(template_path("workflows/ci.yml"))
      },
      %Action.AddFile{
        path: Path.join([app_path, ".github", "actions", "build", "action.yml"]),
        content: File.read!(template_path("actions/build/action.yml"))
      },
      %Action.AddFile{
        path: Path.join([app_path, ".github", "pull_request_template.md"]),
        content: File.read!(template_path("pull_request_template.md"))
      }
    ]
  end

  # --- Template Helpers ---

  defp template_path(filename) do
    Application.app_dir(:catalyst, ["priv", "templates", "github", filename])
  end
end
