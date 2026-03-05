defmodule Catalyst.Plugin.PhoenixBaseTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action
  alias Catalyst.Plugin.PhoenixBase

  test "converts keyword flags to phx.new argv" do
    opts = [
      app_path: "my_app",
      app_name: "My App",
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

    actions = PhoenixBase.run(opts)

    assert %Action.SystemCommand{cmd: "mix", args: args} = Enum.at(actions, 0)

    assert args == [
             "phx.new",
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
    opts = [
      app_path: "my_app",
      app_name: "My App",
      flags: ["--no-install", "--no-ecto", "--module", "MyApp"]
    ]

    actions = PhoenixBase.run(opts)

    assert %Action.SystemCommand{args: ["phx.new", "my_app" | flags]} = Enum.at(actions, 0)
    assert flags == ["--no-install", "--no-ecto", "--module", "MyApp"]
  end

  test "supports explicit no_* false as positive flag" do
    opts = [
      app_path: "my_app",
      app_name: "My App",
      flags: [no_install: false, no_ecto: false]
    ]

    actions = PhoenixBase.run(opts)

    assert %Action.SystemCommand{args: args} = Enum.at(actions, 0)
    assert args == ["phx.new", "my_app", "--install", "--ecto"]
  end
end
