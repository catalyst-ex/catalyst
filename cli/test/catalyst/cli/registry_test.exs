defmodule Catalyst.CLI.RegistryTest do
  use ExUnit.Case, async: false

  alias Catalyst.CLI.Registry

  test "resolves direct module names without a registry" do
    assert {:ok, entry} = Registry.resolve("MyApp.CustomPlugin", registries: [])
    assert entry.name == "MyApp.CustomPlugin"
    assert entry.module == "MyApp.CustomPlugin"
    assert entry.source == :module
  end

  test "resolves plugins from a registry map" do
    registry = %{
      "schema_version" => 1,
      "package" => "catalyst_plugins",
      "requirement" => "~> 1.0",
      "plugins" => %{
        "credo" => "Catalyst.Plugins.Credo"
      }
    }

    assert {:ok, entry} = Registry.resolve("credo", registries: [registry])
    assert entry.name == "credo"
    assert entry.package == "catalyst_plugins"
    assert entry.module == "Catalyst.Plugins.Credo"
    assert entry.requirement == "~> 1.0"
  end

  test "normalizes underscores to hyphens for registry lookup" do
    registry = %{
      "schema_version" => 1,
      "package" => "catalyst_plugins",
      "plugins" => %{
        "github-ci" => "Catalyst.Plugins.GithubCI"
      }
    }

    assert {:ok, entry} = Registry.resolve("github_ci", registries: [registry])
    assert entry.name == "github-ci"
    assert entry.module == "Catalyst.Plugins.GithubCI"
  end

  test "resolves plugins from a registry json file" do
    path = Path.join(System.tmp_dir!(), "catalyst-registry-#{System.unique_integer()}.json")

    File.write!(path, """
    {
      "schema_version": 1,
      "package": "catalyst_plugins",
      "plugins": {
        "sobelow": "Catalyst.Plugins.Sobelow"
      }
    }
    """)

    on_exit(fn -> File.rm(path) end)

    assert {:ok, entry} = Registry.resolve("sobelow", registries: [path])
    assert entry.package == "catalyst_plugins"
    assert entry.module == "Catalyst.Plugins.Sobelow"
  end

  test "uses configured registries without appending the default registry" do
    tmp_dir = Path.join(System.tmp_dir!(), "catalyst-config-#{System.unique_integer()}")
    registry_path = Path.join(tmp_dir, "registry.json")

    File.mkdir_p!(tmp_dir)

    File.write!(Path.join(tmp_dir, ".catalyst.exs"), """
    [
      registries: ["#{registry_path}"]
    ]
    """)

    File.write!(registry_path, """
    {
      "schema_version": 1,
      "package": "custom_plugins",
      "plugins": {
        "custom": "Custom.Plugins.Custom"
      }
    }
    """)

    on_exit(fn -> File.rm_rf(tmp_dir) end)

    File.cd!(tmp_dir, fn ->
      assert {:ok, entry} = Registry.resolve("custom")
      assert entry.package == "custom_plugins"
      assert entry.module == "Custom.Plugins.Custom"
      assert {:error, {:not_found, "credo"}} = Registry.resolve("credo")
    end)
  end

  test "empty configured registries do not fall back to the default registry" do
    tmp_dir = Path.join(System.tmp_dir!(), "catalyst-empty-config-#{System.unique_integer()}")
    File.mkdir_p!(tmp_dir)
    File.write!(Path.join(tmp_dir, ".catalyst.exs"), "[registries: []]")

    on_exit(fn -> File.rm_rf(tmp_dir) end)

    File.cd!(tmp_dir, fn ->
      assert {:error, {:not_found, "credo"}} = Registry.resolve("credo")
    end)
  end

  test "returns not found for unknown plugin names" do
    assert {:error, {:not_found, "unknown"}} =
             Registry.resolve("unknown",
               registries: [
                 %{
                   "schema_version" => 1,
                   "package" => "catalyst_plugins",
                   "plugins" => %{}
                 }
               ]
             )
  end
end
