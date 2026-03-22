defmodule Catalyst.Actions.AddDependencyTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions
  alias Catalyst.Actions.Executor
  alias Catalyst.Execution

  test "AddDependency exposes expected keys" do
    expected_keys = [:__struct__, :name, :opts, :version] |> Enum.sort()
    actual_keys = Actions.AddDependency.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AddDependency can be instantiated" do
    action =
      struct(Actions.AddDependency,
        name: :plug,
        version: "~> 1.0",
        opts: [only: :dev]
      )

    assert %Actions.AddDependency{} = action
    assert action.name == :plug
    assert action.version == "~> 1.0"
    assert action.opts == [only: :dev]
  end

  test "AddDependency updates project source end to end" do
    app_path = create_tmp_project!("add_dependency")
    execution = Execution.new(app_path: app_path)

    action =
      struct(Actions.AddDependency,
        name: :plug,
        version: "~> 1.0",
        opts: [only: :dev]
      )

    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert mix_source =~ ":plug"
    assert mix_source =~ "\"~> 1.0\""
    assert mix_source =~ "only: :dev"
  end

  test "AddDependency does not duplicate dependency when applied twice" do
    app_path = create_tmp_project!("add_dependency_no_dupe")
    execution = Execution.new(app_path: app_path)

    action =
      struct(Actions.AddDependency,
        name: :plug,
        version: "~> 1.0",
        opts: []
      )

    Executor.run(action, execution)
    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert length(Regex.scan(~r/\bplug:\s*"~> 1\.0"/, mix_source)) == 1
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
