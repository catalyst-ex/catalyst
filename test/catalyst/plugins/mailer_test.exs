defmodule Catalyst.Plugins.MailerTest do
  use Catalyst.TestSupport.ProjectCase, async: false

  @moduletag setup_project: true

  alias Catalyst.Actions.Executor
  alias Catalyst.Actions
  alias Catalyst.Plugins.Mailer

  test "applies mailer plugin actions end to end", %{app_path: app_path} do
    tmp_root = Path.dirname(app_path)
    app_dir = Path.basename(app_path)

    actions =
      File.cd!(tmp_root, fn ->
        test_execution(app_dir,
          app_name: app_dir,
          app_module: "MyApp",
          otp_app: :my_app
        )
        |> Mailer.run()
      end)

    execution = test_execution(app_dir, app_name: app_dir, app_module: "MyApp", otp_app: :my_app)

    File.cd!(tmp_root, fn ->
      Enum.each(actions, fn action ->
        if match?({Actions.MixTask, _}, action) do
          :ok
        else
          Executor.run(action, execution)
        end
      end)
    end)

    mix_source = File.read!(Path.join(app_path, "mix.exs"))
    config_source = File.read!(Path.join(app_path, "config/config.exs"))
    mailer_source = File.read!(Path.join([app_path, "lib", app_dir <> "_mailer", "mailer.ex"]))
    email_source = File.read!(Path.join([app_path, "lib", app_dir <> "_mailer", "email.ex"]))

    default_layout_source =
      File.read!(
        Path.join([app_path, "lib", app_dir <> "_mailer", "layouts", "default_layout.ex"])
      )

    assert mix_source =~ ~s(swoosh: "~> 1.16")
    assert config_source =~ "config(:my_app, MyApp.Mailer"
    assert config_source =~ "adapter: Swoosh.Adapters.Local"
    assert config_source =~ "config(:swoosh, :api_client, false)"
    assert mailer_source =~ "defmodule Elixir.MyApp.Mailer do"
    assert mailer_source =~ "use Swoosh.Mailer, otp_app: :my_app"
    assert email_source =~ "use MyAppWeb, :verified_routes"
    assert email_source =~ "import MyApp.Mailer.Layouts.DefaultLayout"
    assert email_source =~ "alias MyApp.Mailer"
    assert email_source =~ "|> MyApp.Mailer.deliver!()"
    refute email_source =~ "Catalyst"
    assert default_layout_source =~ "defmodule MyApp.Mailer.Layouts.DefaultLayout do"
    refute default_layout_source =~ "Catalyst"

    assert {Actions.MixTask, deps_opts} = Enum.find(actions, &match?({Actions.MixTask, _}, &1))
    assert Keyword.get(deps_opts, :name) == "deps.get"
  end

  test "uses normalized OTP app when display app_name has spaces", %{app_path: app_path} do
    tmp_root = Path.dirname(app_path)
    app_dir = Path.basename(app_path)

    actions =
      File.cd!(tmp_root, fn ->
        test_execution(app_dir,
          app_name: "My App",
          app_module: "MyApp",
          otp_app: :my_app
        )
        |> Mailer.run()
      end)

    execution = test_execution(app_dir, app_name: "My App", app_module: "MyApp", otp_app: :my_app)

    File.cd!(tmp_root, fn ->
      Enum.each(actions, fn action ->
        if match?({Actions.MixTask, _}, action) do
          :ok
        else
          Executor.run(action, execution)
        end
      end)
    end)

    config_source = File.read!(Path.join(app_path, "config/config.exs"))
    mailer_path = Path.join([app_path, "lib", app_dir <> "_mailer", "mailer.ex"])

    assert config_source =~ "config(:my_app, MyApp.Mailer"
    refute config_source =~ ~s(config(:"My App", MyApp.Mailer")
    assert File.exists?(mailer_path)
    refute File.exists?(Path.join([app_path, "lib", "My App", "mailer.ex"]))
  end

  test "post_validate defaults to an empty validation action list", %{app_path: app_path} do
    tmp_root = Path.dirname(app_path)
    app_dir = Path.basename(app_path)

    result =
      File.cd!(tmp_root, fn ->
        Mailer.post_validate(test_execution(app_dir, app_module: "MyApp"), [])
      end)

    assert result == []
  end
end
