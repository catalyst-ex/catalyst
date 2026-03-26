defmodule Catalyst.Plugins.PhoenixBaseTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  alias Catalyst.Actions
  alias Catalyst.Plugins.PhoenixBase
  alias Catalyst.ValidationAction

  test "converts keyword flags to phx.new argv" do
    execution =
      test_execution("my_app", app_name: "My App", app_module: "MyApp", otp_app: :my_app)

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
    execution =
      test_execution("my_app", app_name: "My App", app_module: "MyApp", otp_app: :my_app)

    opts = [flags: ["--no-install", "--no-ecto", "--module", "MyApp"]]

    actions = PhoenixBase.run(execution, opts)

    assert %Actions.MixTask{name: "phx.new", args: ["my_app" | flags]} = Enum.at(actions, 0)
    assert flags == ["--no-install", "--no-ecto", "--module", "MyApp"]
  end

  test "supports explicit no_* false as positive flag" do
    execution =
      test_execution("my_app", app_name: "My App", app_module: "MyApp", otp_app: :my_app)

    opts = [flags: [no_install: false, no_ecto: false]]

    actions = PhoenixBase.run(execution, opts)

    assert %Actions.MixTask{name: "phx.new", args: args} = Enum.at(actions, 0)
    assert args == ["my_app", "--install", "--ecto"]
  end

  test "does not scaffold when targeting existing project" do
    execution =
      test_execution("my_app",
        app_name: "My App",
        app_module: "MyApp",
        otp_app: :my_app,
        mode: :existing
      )

    opts = [flags: [install: false]]

    actions = PhoenixBase.run(execution, opts)

    assert actions == []
  end

  test "post_validate verifies phx.new/deps.get side effects in new mode" do
    execution =
      test_execution("my_app",
        app_name: "My App",
        app_module: "MyApp",
        otp_app: :my_app,
        mode: :new
      )

    validations = PhoenixBase.post_validate(execution, [])

    assert [%ValidationAction{} = validation] = validations
    assert validation.required

    assert %Actions.Function{
             module: Catalyst.Plugins.PhoenixBase,
             function: :validate_scaffolded_project!,
             args: [^execution]
           } =
             validation.action
  end

  test "post_validate is empty in existing mode" do
    execution =
      test_execution("my_app",
        app_name: "My App",
        app_module: "MyApp",
        otp_app: :my_app,
        mode: :existing
      )

    assert PhoenixBase.post_validate(execution, []) == []
  end
end
