defmodule Catalyst.Plugins.PhoenixBaseTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions
  alias Catalyst.Execution
  alias Catalyst.Plugins.PhoenixBase

  test "converts keyword flags to phx.new argv" do
    execution = Execution.new(app_path: "my_app", app_name: "My App")

    opts = [
      flags: [
        install: false,
        umbrella: true,
        module: "MyApp",
        database: :sqlite3,
        no_mailer: true,
        no_ecto: true,
        no_assets: true,
        no_version_check: true,
        no_dashboard: nil
      ]
    ]

    actions = PhoenixBase.run(execution, opts)

    assert %Actions.MixTask{name: "phx.new", args: args} = Enum.at(actions, 0)

    assert args == [
             "my_app",
             "--no-install",
             "--umbrella",
             "--module",
             "MyApp",
             "--database",
             "sqlite3",
             "--no-mailer",
             "--no-ecto",
             "--no-assets",
             "--no-version-check"
           ]
  end

  test "keeps backward compatibility with raw string flags" do
    execution = Execution.new(app_path: "my_app", app_name: "My App")

    opts = [flags: ["--no-install", "--no-ecto", "--module", "MyApp"]]

    actions = PhoenixBase.run(execution, opts)

    assert %Actions.MixTask{name: "phx.new", args: ["my_app" | flags]} = Enum.at(actions, 0)
    assert flags == ["--no-install", "--no-ecto", "--module", "MyApp"]
  end

  test "supports explicit no_* false as positive flag" do
    execution = Execution.new(app_path: "my_app", app_name: "My App")

    opts = [flags: [no_install: false, no_ecto: false]]

    actions = PhoenixBase.run(execution, opts)

    assert %Actions.MixTask{name: "phx.new", args: args} = Enum.at(actions, 0)
    assert args == ["my_app", "--install", "--ecto"]
  end

  test "does not scaffold when targeting existing project" do
    execution = Execution.new(app_path: "my_app", app_name: "My App", mode: :existing)

    opts = [flags: [install: false]]

    actions = PhoenixBase.run(execution, opts)

    assert actions == []
  end
end
