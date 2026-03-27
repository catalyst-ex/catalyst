defmodule Catalyst.TestSupport.ProjectCase do
  use ExUnit.CaseTemplate

  alias Catalyst.Execution

  using opts do
    quote bind_quoted: [opts: opts] do
      use ExUnit.Case, opts
      import Catalyst.TestSupport.ProjectCase
    end
  end

  setup tags do
    if tags[:setup_project] do
      base_name = tags[:project_name] || to_string(tags[:test] || "catalyst_project")
      app_path = create_setup_project!(base_name)
      {:ok, %{app_path: app_path}}
    else
      :ok
    end
  end

  def create_setup_project!(name, opts \\ []) do
    base = Path.join(System.tmp_dir!(), "catalyst_tests")
    uniq = Integer.to_string(System.unique_integer([:positive, :monotonic]))

    safe_name =
      name
      |> to_string()
      |> String.replace(~r/[^a-zA-Z0-9_\-]/, "_")

    app_path = Path.join(base, "#{safe_name}_#{uniq}")

    File.mkdir_p!(app_path)
    File.mkdir_p!(Path.join(app_path, "config"))
    File.write!(Path.join(app_path, "mix.exs"), mix_project_source(opts))
    File.write!(Path.join(app_path, "config/config.exs"), config_source())
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf(app_path) end)

    app_path
  end

  def mix_project_source(opts \\ []) do
    with_aliases = Keyword.get(opts, :with_aliases, true)

    aliases_source =
      if with_aliases do
        """
        defp aliases do
          []
        end
        """
      else
        """
        defp aliases do
          []
        end
        """
      end

    """
    defmodule TmpProject.MixProject do
      use Mix.Project

      def project do
        [
          app: :setup_project,
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

      #{aliases_source}
    end
    """
  end

  def config_source do
    """
    import Config
    """
  end

  def test_execution(app_path, opts \\ []) do
    app_name = Keyword.get(opts, :app_name, "tmp")
    app_module = Keyword.get(opts, :app_module, "Tmp")
    otp_app = Keyword.get(opts, :otp_app, :tmp)
    mode = Keyword.get(opts, :mode, :new)
    plugins = Keyword.get(opts, :plugins, [])

    config = %{
      app: %{
        path: app_path,
        name: app_name,
        module: app_module,
        otp_app: otp_app
      },
      mode: mode,
      plugins: plugins
    }

    Execution.new(config: config)
  end
end
