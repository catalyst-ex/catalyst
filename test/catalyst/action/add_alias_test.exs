defmodule Catalyst.Action.AddAliasTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action
  alias Catalyst.Action.Executor

  test "AddAlias exposes expected keys" do
    expected_keys = [:__struct__, :commands, :key, :target_file] |> Enum.sort()
    actual_keys = Action.AddAlias.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AddAlias can be instantiated" do
    action =
      struct(Action.AddAlias,
        key: :setup,
        commands: ["deps.get", "compile"],
        target_file: "mix.exs"
      )

    assert %Action.AddAlias{} = action
    assert action.key == :setup
    assert action.commands == ["deps.get", "compile"]
    assert action.target_file == "mix.exs"
  end

  test "AddAlias updates project source end to end" do
    app_path = create_tmp_project!("add_alias")
    mix_exs = Path.join(app_path, "mix.exs")

    action =
      struct(Action.AddAlias,
        key: :quality,
        commands: ["format", "credo"],
        target_file: mix_exs
      )

    Executor.run(action)

    mix_source = File.read!(mix_exs)
    assert mix_source =~ "quality: [\"format\", \"credo\"]"
  end

  test "AddAlias does not duplicate commands under quality when applied twice" do
    app_path = create_tmp_project!("add_alias_quality_no_dupe")
    mix_exs = Path.join(app_path, "mix.exs")

    action =
      struct(Action.AddAlias,
        key: :quality,
        commands: ["format", "credo"],
        target_file: mix_exs
      )

    Executor.run(action)
    Executor.run(action)

    mix_source = File.read!(mix_exs)

    assert length(Regex.scan(~r/quality:\s*\[/, mix_source)) == 1
    assert length(Regex.scan(~r/"format"/, mix_source)) == 1
    assert length(Regex.scan(~r/"credo"/, mix_source)) == 1
  end

  test "AddAlias does not duplicate commands for other aliases" do
    app_path = create_tmp_project!("add_alias_setup_no_dupe")
    mix_exs = Path.join(app_path, "mix.exs")

    action =
      struct(Action.AddAlias,
        key: :setup,
        commands: ["deps.get", "compile"],
        target_file: mix_exs
      )

    Executor.run(action)
    Executor.run(action)

    mix_source = File.read!(mix_exs)

    assert length(Regex.scan(~r/setup:\s*\[/, mix_source)) == 1
    assert length(Regex.scan(~r/"deps\.get"/, mix_source)) == 1
    assert length(Regex.scan(~r/"compile"/, mix_source)) == 1
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
