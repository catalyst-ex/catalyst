defmodule Catalyst.CLI.PluginRuntime do
  @moduledoc false

  alias Catalyst.CLI.IO
  alias Catalyst.Registry

  @catalyst_version Mix.Project.config()[:version]

  defmodule Dependency do
    @moduledoc false

    @enforce_keys [:package, :requirement]
    defstruct [:package, :requirement]
  end

  def dependencies(plugin_specs, opts \\ []) when is_list(plugin_specs) do
    plugin_specs
    |> Enum.map(&plugin_module/1)
    |> Enum.uniq()
    |> Enum.reject(&Code.ensure_loaded?/1)
    |> Enum.map(&resolve_dependency!(&1, opts))
    |> Enum.uniq_by(& &1.package)
  end

  def run(config_path, working_dir, dependencies)
      when is_binary(config_path) and is_binary(working_dir) and is_list(dependencies) do
    runtime_dir = runtime_dir()
    File.mkdir_p!(runtime_dir)

    try do
      write_runtime_project!(runtime_dir, dependencies)

      IO.info("Fetching #{dependency_summary(dependencies)}...")
      run_mix!(runtime_dir, ["deps.get"])

      IO.info("Running Catalyst with remote plugins...")

      run_mix!(runtime_dir, [
        "run",
        "runner.exs",
        "--",
        Path.expand(config_path, working_dir),
        working_dir
      ])
    after
      File.rm_rf!(runtime_dir)
    end
  end

  defp plugin_module({module, opts}) when is_atom(module) and is_list(opts), do: module
  defp plugin_module({module}) when is_atom(module), do: module
  defp plugin_module(module) when is_atom(module), do: module
  defp plugin_module(_invalid), do: nil

  defp resolve_dependency!(nil, _opts), do: Mix.raise("Invalid plugin specification")

  defp resolve_dependency!(module, opts) do
    case Registry.resolve_module(module, opts) do
      {:ok, %{package: package, requirement: requirement}} when is_binary(package) ->
        validate_package!(package)
        %Dependency{package: package, requirement: requirement || ">= 0.0.0"}

      {:error, reason} ->
        Mix.raise("Could not resolve plugin module #{inspect(module)}: #{inspect(reason)}")
    end
  end

  defp validate_package!(package) do
    unless package =~ ~r/^[a-z][a-z0-9_]*$/ do
      Mix.raise("Invalid plugin package in registry: #{inspect(package)}")
    end
  end

  defp runtime_dir do
    unique = System.unique_integer([:positive, :monotonic])
    Path.join(System.tmp_dir!(), "catalyst-runtime-#{unique}")
  end

  defp write_runtime_project!(runtime_dir, dependencies) do
    File.write!(Path.join(runtime_dir, "mix.exs"), mix_project(dependencies))
    File.write!(Path.join(runtime_dir, "runner.exs"), runner_script())
  end

  defp mix_project(dependencies) do
    deps =
      [%Dependency{package: "catalyst", requirement: @catalyst_version} | dependencies]
      |> Enum.uniq_by(& &1.package)
      |> Enum.map_join(",\n        ", fn dependency ->
        inspect({String.to_atom(dependency.package), dependency.requirement})
      end)

    """
    defmodule Catalyst.Runtime.MixProject do
      use Mix.Project

      def project do
        [
          app: :catalyst_runtime,
          version: "0.0.0",
          deps: [
            #{deps}
          ]
        ]
      end
    end
    """
  end

  defp runner_script do
    """
    [config_path, working_dir] =
      case System.argv() do
        ["--", config_path, working_dir] -> [config_path, working_dir]
        args -> args
      end

    File.cd!(working_dir, fn ->
      config = Catalyst.Config.Loader.load!(config_path)

      case config.mode do
        :existing ->
          unless File.exists?(config.app.path) do
            Mix.raise("Existing project does not exist: \#{config.app.path}")
          end

          mix_file = Path.join(config.app.path, "mix.exs")

          unless File.exists?(mix_file) do
            Mix.raise("Existing project does not contain a mix.exs: \#{mix_file}")
          end

        :new ->
          if File.exists?(config.app.path) do
            Mix.raise("Target path already exists: \#{config.app.path}")
          end
      end

      {:ok, _execution} = Catalyst.build(config)
      Mix.shell().info("Done! Catalyst finished in \#{Path.expand(config.app.path)}")
    end)
    """
  end

  defp run_mix!(runtime_dir, args) do
    mix = System.find_executable("mix") || Mix.raise("Could not find the mix executable")

    {_output, status} =
      System.cmd(mix, args,
        cd: runtime_dir,
        env: [{"MIX_ENV", "prod"}],
        into: Elixir.IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("Temporary Catalyst runtime failed with exit status #{status}")
    end
  end

  defp dependency_summary(dependencies) do
    dependencies
    |> Enum.map_join(", ", &"#{&1.package} #{&1.requirement}")
  end
end
