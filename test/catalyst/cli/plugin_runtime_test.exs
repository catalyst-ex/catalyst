defmodule Catalyst.CLI.PluginRuntimeTest do
  use ExUnit.Case, async: true

  alias Catalyst.CLI.PluginRuntime

  defmodule CustomPlugin do
    use Catalyst.Plugin

    @impl true
    def run(_execution, _opts), do: []
  end

  @registry %{
    "schema_version" => 1,
    "package" => "catalyst_plugins",
    "requirement" => "1.0.0-beta.0",
    "plugins" => %{
      "Credo" => "Catalyst.Plugins.Credo",
      "Sobelow" => "Catalyst.Plugins.Sobelow"
    }
  }

  test "resolves unloaded plugin modules to package dependencies" do
    dependencies =
      PluginRuntime.dependencies(
        [Catalyst.Plugins.Credo, {Catalyst.Plugins.Sobelow, strict: true}],
        registries: [@registry]
      )

    assert dependencies == [
             %PluginRuntime.Dependency{
               package: "catalyst_plugins",
               requirement: "1.0.0-beta.0"
             }
           ]
  end

  test "does not fetch packages for custom plugins already loaded by the config" do
    assert PluginRuntime.dependencies([CustomPlugin], registries: []) == []
  end
end
