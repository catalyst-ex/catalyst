defmodule Catalyst.Plugins.MailerTest do
  use Catalyst.TestSupport.ProjectCase, async: false

  @moduletag setup_project: true

  alias Catalyst.Actions
  alias Catalyst.Execution
  alias Catalyst.Plugins.Mailer

  test "applies mailer plugin actions end to end", %{app_path: app_path} do
    tmp_root = Path.dirname(app_path)
    app_dir = Path.basename(app_path)

    actions =
      File.cd!(tmp_root, fn ->
        Execution.new(
          app_path: app_dir,
          app_name: app_dir,
          app_module: "MyApp",
          otp_app: :my_app
        )
        |> Mailer.run()
      end)

    execution = Execution.new(app_path: app_dir, otp_app: :my_app)

    File.cd!(tmp_root, fn ->
      Enum.each(actions, fn
        %Actions.MixTask{} -> :ok
        action -> Actions.Executor.run(action, execution)
      end)
    end)

    mix_source = File.read!(Path.join(app_path, "mix.exs"))
    config_source = File.read!(Path.join(app_path, "config/config.exs"))
    mailer_source = File.read!(Path.join([app_path, "lib", app_dir, "mailer.ex"]))

    assert mix_source =~ "swoosh: \"~> 1.16\""
    assert config_source =~ "config(:my_app, MyApp.Mailer"
    assert config_source =~ "adapter: Swoosh.Adapters.Local"
    assert config_source =~ "config(:swoosh, :api_client, false)"
    assert mailer_source =~ "defmodule Elixir.MyApp.Mailer do"
    assert mailer_source =~ "use Swoosh.Mailer, otp_app: :my_app"

    assert %Actions.MixTask{name: "deps.get"} =
             Enum.find(actions, &match?(%Actions.MixTask{}, &1))
  end

  test "uses normalized OTP app when display app_name has spaces", %{app_path: app_path} do
    tmp_root = Path.dirname(app_path)
    app_dir = Path.basename(app_path)

    actions =
      File.cd!(tmp_root, fn ->
        Execution.new(
          app_path: app_dir,
          app_name: "My App",
          app_module: "MyApp",
          otp_app: :my_app
        )
        |> Mailer.run()
      end)

    execution = Execution.new(app_path: app_dir, app_name: "My App", otp_app: :my_app)

    File.cd!(tmp_root, fn ->
      Enum.each(actions, fn
        %Actions.MixTask{} -> :ok
        action -> Actions.Executor.run(action, execution)
      end)
    end)

    config_source = File.read!(Path.join(app_path, "config/config.exs"))
    mailer_path = Path.join([app_path, "lib", app_dir, "mailer.ex"])

    assert config_source =~ "config(:my_app, MyApp.Mailer"
    refute config_source =~ "config(:\"My App\", MyApp.Mailer"
    assert File.exists?(mailer_path)
    refute File.exists?(Path.join([app_path, "lib", "My App", "mailer.ex"]))
  end

  test "post_validate defaults to an empty validation action list", %{app_path: app_path} do
    tmp_root = Path.dirname(app_path)
    app_dir = Path.basename(app_path)

    result =
      File.cd!(tmp_root, fn ->
        Mailer.post_validate(Execution.new(app_path: app_dir, app_module: "MyApp"), [])
      end)

    assert result == []
  end
end
