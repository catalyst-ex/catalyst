defmodule Catalyst.Plugins.SobelowTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions
  alias Catalyst.Execution
  alias Catalyst.Plugin
  alias Catalyst.Plugins.Sobelow

  test "applies sobelow plugin actions end to end" do
    app_path = create_tmp_project!("sobelow_app")
    execution = Execution.new(app_path: app_path)
    gitignore = Path.join(app_path, ".gitignore")
    File.write!(gitignore, "_build\n")

    actions =
      execution
      |> Sobelow.run()
      |> Plugin.normalize_actions()

    Enum.each(actions, fn
      %Actions.MixTask{} -> :ok
      action -> Actions.Executor.run(action, execution)
    end)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)

    assert mix_source =~ "{:sobelow, \"0.14.0\", only: [:dev, :test], runtime: false}"
    assert mix_source =~ "quality: [\"format\", \"sobelow --exit low\"]"

    gitignore_source = File.read!(gitignore)
    assert gitignore_source =~ "# Sobelow Security Logs"
    assert gitignore_source =~ ".sobelow"

    assert %Actions.MixTask{name: "deps.get"} =
             Enum.find(actions, &match?(%Actions.MixTask{}, &1))
  end

  defp create_tmp_project!(name) do
    base = Path.join(System.tmp_dir!(), "catalyst_tests")
    uniq = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    app_path = Path.join(base, "#{name}_#{uniq}")

    File.mkdir_p!(app_path)
    File.write!(Path.join(app_path, "mix.exs"), mix_project_source())
    on_exit(fn -> File.rm_rf(app_path) end)

    app_path
  end

  defp mix_project_source do
    """
    defmodule TmpProject.MixProject do
      use Mix.Project

      def project do
        [
          app: :tmp_project,
          version: \"0.1.0\",
          elixir: \"~> 1.15\",
          aliases: aliases(),
          deps: deps()
        ]
      end

      def application do
        [extra_applications: [:logger]]
      end

      defp deps do
        []
      end

      defp aliases do
        []
      end
    end
    """
  end
end
