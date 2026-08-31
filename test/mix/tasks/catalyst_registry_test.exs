defmodule Mix.Tasks.Catalyst.RegistryTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Catalyst.Registry

  setup do
    tmp_dir =
      Path.join(System.tmp_dir!(), "catalyst-registry-test-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)

    on_exit(fn -> File.rm_rf(tmp_dir) end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "generates registry from plugin source files", %{tmp_dir: tmp_dir} do
    named_module = unique_module("NamedPlugin")
    fallback_module = unique_module("FallbackPlugin")

    named_file =
      write_plugin!(tmp_dir, named_module, """
      @impl true
      def name, do: :custom_name
      """)

    fallback_file = write_plugin!(tmp_dir, fallback_module)
    out_path = Path.join(tmp_dir, "registry.json")

    Registry.run(["--out", out_path, named_file, fallback_file])

    registry =
      out_path
      |> File.read!()
      |> JSON.decode!()

    assert registry["schema_version"] == 1
    assert registry["package"] == "catalyst"
    assert registry["requirement"] == Mix.Project.config()[:version]

    assert registry["plugins"]["custom_name"] == inspect(named_module)

    assert registry["plugins"][fallback_module |> Module.split() |> List.last()] ==
             inspect(fallback_module)
  end

  test "supports string plugin names", %{tmp_dir: tmp_dir} do
    module = unique_module("StringNamedPlugin")

    file =
      write_plugin!(tmp_dir, module, """
      @impl true
      def name, do: "string-name"
      """)

    out_path = Path.join(tmp_dir, "registry.json")

    Registry.run(["--out", out_path, file])

    registry =
      out_path
      |> File.read!()
      |> JSON.decode!()

    assert registry["plugins"]["string-name"] == inspect(module)
  end

  test "raises when file does not define a plugin", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "not_a_plugin.ex")

    File.write!(file, """
    defmodule #{inspect(unique_module("NotAPlugin"))} do
    end
    """)

    assert_raise Mix.Error, ~r/Expected .* to define at least one Catalyst plugin/, fn ->
      Registry.run([file])
    end
  end

  test "raises without input files" do
    assert_raise Mix.Error, ~r/Usage: mix catalyst.registry/, fn ->
      Registry.run([])
    end
  end

  defp write_plugin!(tmp_dir, module, body \\ "") do
    path =
      Path.join(
        tmp_dir,
        module |> Module.split() |> List.last() |> Macro.underscore() |> Kernel.<>(".ex")
      )

    File.write!(path, """
    defmodule #{inspect(module)} do
      use Catalyst.Plugin

      #{body}

      @impl true
      def run(_execution, _opts), do: []
    end
    """)

    path
  end

  defp unique_module(suffix) do
    Module.concat([RegistryTestFixtures, "#{suffix}#{System.unique_integer([:positive])}"])
  end
end
