defmodule Mix.Tasks.Catalyst.New do
  use Mix.Task

  @shortdoc "Creates a new Elixir application (Default: Phoenix, use --plain for basic)"

  def run(args) do
    {opts, argv} = OptionParser.parse!(args, switches: [plain: :boolean])
    {app_name, _} = parse_app_name(argv)

    app_file = Macro.underscore(app_name)
    app_module = Macro.camelize(app_name)

    # logic to swap the base plugin
    base_plugin =
      if opts[:plain] do
        {Catalyst.Plugin.ElixirBase, sup: true}
      else
        # Default to Phoenix
        {Catalyst.Plugin.PhoenixBase, phoenix: "1.7.10"}
      end

    config = %Catalyst.Config{
      version: 1,
      app: %Catalyst.Config.App{
        name: app_name,
        file: app_file,
        module: app_module
      },
      plugins: [
        base_plugin
        # Future plugins go here
      ]
    }

    Catalyst.build(config)
    IO.puts("Done! Project ready in /#{app_file}")
  end

  defp parse_app_name([name | _]), do: {name, []}
  defp parse_app_name([]), do: Mix.raise("Usage: mix catalyst.new MyApp [--plain]")
end
