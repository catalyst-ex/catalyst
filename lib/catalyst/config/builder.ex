defmodule Catalyst.Config.Builder do
  alias Catalyst.Config

  @allowed_modes [:new, :existing]

  def build!(%Config{} = config) do
    config
    |> normalize_mode()
    |> normalize_app()
    |> normalize_plugins()
    |> validate!()
  end

  def build!(config) when is_list(config), do: config |> Enum.into(%{}) |> build!()

  def build!(%{} = config) do
    app = Map.get(config, :app, %{})

    %Config{
      version: Map.get(config, :version),
      mode: Map.get(config, :mode),
      app: to_app_struct(app),
      plugins: Map.get(config, :plugins, [])
    }
    |> build!()
  end

  def build!(other) do
    raise "Config must be a %Catalyst.Config{} struct, map, or keyword list, got: #{inspect(other)}"
  end

  defp to_app_struct(%Config.App{} = app), do: app

  defp to_app_struct(app) when is_list(app), do: app |> Enum.into(%{}) |> to_app_struct()

  defp to_app_struct(%{} = app) do
    %Config.App{
      name: Map.get(app, :name),
      path: Map.get(app, :path),
      module: Map.get(app, :module)
    }
  end

  defp to_app_struct(other) do
    raise "Config Error: app must be a %Catalyst.Config.App{} struct, map, or keyword list, got: #{inspect(other)}"
  end

  defp normalize_mode(config) do
    mode = config.mode || infer_mode(config.app.path)
    %{config | mode: mode}
  end

  defp infer_mode(nil), do: :new

  defp infer_mode(path) when is_binary(path) do
    if File.exists?(path), do: :existing, else: :new
  end

  defp normalize_app(%Config{app: %Config.App{} = app} = config) do
    app_path = app.path || default_app_path(config.mode)
    app_name = app.name || infer_app_name(app_path)
    app_module = app.module || infer_app_module(app_name)

    %{config | app: %{app | path: app_path, name: app_name, module: app_module}}
  end

  defp default_app_path(:existing), do: "."
  defp default_app_path(_), do: nil

  defp infer_app_name(nil), do: nil

  defp infer_app_name(path) do
    path
    |> Path.expand()
    |> Path.basename()
  end

  defp infer_app_module(nil), do: nil

  defp infer_app_module(name) do
    name
    |> to_string()
    |> Macro.camelize()
  end

  defp normalize_plugins(%Config{} = config) do
    %{config | plugins: config.plugins || []}
  end

  defp validate!(%Config{} = config) do
    cond do
      config.mode not in @allowed_modes ->
        raise "Config Error: mode must be one of #{inspect(@allowed_modes)}"

      is_nil(config.app.path) ->
        raise "Config Error: app.path is missing"

      is_nil(config.app.name) ->
        raise "Config Error: app.name is missing"

      is_nil(config.app.module) ->
        raise "Config Error: app.module is missing"

      !is_list(config.plugins) ->
        raise "Config Error: plugins must be a list"

      true ->
        config
    end
  end
end
