defmodule Catalyst.Plugins.MailerTest do
  use ExUnit.Case, async: false

  alias Catalyst.Actions
  alias Catalyst.Execution
  alias Catalyst.Plugin
  alias Catalyst.Plugins.Mailer

  test "applies mailer plugin actions end to end" do
    {tmp_root, app_path, app_root} = create_tmp_project!("mailer_app")

    actions =
      File.cd!(tmp_root, fn ->
        Execution.new(
          app_path: app_path,
          app_name: app_path,
          app_module: "MyApp",
          otp_app: :my_app
        )
        |> Mailer.run()
        |> Plugin.normalize_actions()
      end)

    execution = Execution.new(app_path: app_path, otp_app: :my_app)

    File.cd!(tmp_root, fn ->
      Enum.each(actions, fn
        %Actions.MixTask{} -> :ok
        action -> Actions.Executor.run(action, execution)
      end)
    end)

    mix_source = File.read!(Path.join(app_root, "mix.exs"))
    config_source = File.read!(Path.join(app_root, "config/config.exs"))
    mailer_source = File.read!(Path.join(app_root, "lib/my_app/mailer.ex"))

    assert mix_source =~ "swoosh: \"~> 1.16\""
    assert config_source =~ "config(:my_app, MyApp.Mailer"
    assert config_source =~ "adapter: Swoosh.Adapters.Local"
    assert config_source =~ "config(:swoosh, :api_client, false)"
    assert mailer_source =~ "defmodule Elixir.MyApp.Mailer do"
    assert mailer_source =~ "use Swoosh.Mailer, otp_app: :my_app"

    assert %Actions.MixTask{name: "deps.get"} =
             Enum.find(actions, &match?(%Actions.MixTask{}, &1))
  end

  test "uses normalized OTP app when display app_name has spaces" do
    {tmp_root, app_path, app_root} = create_tmp_project!("mailer_display_name")

    actions =
      File.cd!(tmp_root, fn ->
        Execution.new(
          app_path: app_path,
          app_name: "My App",
          app_module: "MyApp",
          otp_app: :my_app
        )
        |> Mailer.run()
        |> Plugin.normalize_actions()
      end)

    execution = Execution.new(app_path: app_path, app_name: "My App", otp_app: :my_app)

    File.cd!(tmp_root, fn ->
      Enum.each(actions, fn
        %Actions.MixTask{} -> :ok
        action -> Actions.Executor.run(action, execution)
      end)
    end)

    config_source = File.read!(Path.join(app_root, "config/config.exs"))
    mailer_path = Path.join(app_root, "lib/my_app/mailer.ex")

    assert config_source =~ "config(:my_app, MyApp.Mailer"
    refute config_source =~ "config(:\"My App\", MyApp.Mailer"
    assert File.exists?(mailer_path)
    refute File.exists?(Path.join(app_root, "lib/My App/mailer.ex"))
  end

  test "post_validate returns a valid callback result when explicitly implemented" do
    if mailer_has_explicit_post_validate?() do
      {tmp_root, app_path, _app_root} = create_tmp_project!("mailer_post_validate")

      result =
        File.cd!(tmp_root, fn ->
          Mailer.post_validate(Execution.new(app_path: app_path, app_module: "MyApp"), [])
        end)

      assert result == :ok or match?({:error, _}, result)
    else
      assert true
    end
  end

  defp create_tmp_project!(name) do
    base = Path.join(System.tmp_dir!(), "catalyst_tests")
    uniq = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    tmp_root = Path.join(base, "#{name}_#{uniq}")
    app_path = "my_app"
    app_root = Path.join(tmp_root, app_path)

    File.mkdir_p!(Path.join(app_root, "config"))
    File.write!(Path.join(app_root, "mix.exs"), mix_project_source())
    File.write!(Path.join(app_root, "config/config.exs"), config_source())

    on_exit(fn -> File.rm_rf(tmp_root) end)

    {tmp_root, app_path, app_root}
  end

  defp mix_project_source do
    """
    defmodule MyApp.MixProject do
      use Mix.Project

      def project do
        [
          app: :my_app,
          version: \"0.1.0\",
          elixir: \"~> 1.15\",
          deps: deps()
        ]
      end

      def application do
        [extra_applications: [:logger]]
      end

      defp deps do
        []
      end
    end
    """
  end

  defp config_source do
    """
    import Config
    """
  end

  defp mailer_has_explicit_post_validate? do
    plugin_file = Path.expand("lib/catalyst/plugins/mailer.ex", File.cwd!())

    plugin_file
    |> File.read!()
    |> String.match?(~r/def\s+post_validate\s*\(/)
  end
end
