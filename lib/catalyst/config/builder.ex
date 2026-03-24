defmodule Catalyst.Config.Builder do
  alias Catalyst.Config
  alias Catalyst.Error

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
    raise Error,
      code: :invalid_config_type,
      reason: :invalid_type,
      context: %{value: other}
  end

  defp to_app_struct(%Config.App{} = app), do: app

  defp to_app_struct(app) when is_list(app), do: app |> Enum.into(%{}) |> to_app_struct()

  defp to_app_struct(%{} = app) do
    %Config.App{
      name: Map.get(app, :name),
      path: Map.get(app, :path),
      module: Map.get(app, :module),
      otp_app: Map.get(app, :otp_app)
    }
  end

  defp to_app_struct(other) do
    raise Error,
      code: :invalid_app_config_type,
      reason: :invalid_type,
      context: %{value: other}
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
    app_name = app.name
    app_module = app.module || infer_app_module(app_name)
    app_otp = app.otp_app

    %{config | app: %{app | path: app_path, name: app_name, module: app_module, otp_app: app_otp}}
  end

  defp default_app_path(:existing), do: "."
  defp default_app_path(_), do: nil

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
        raise Error,
          code: :invalid_mode,
          reason: :validation_error,
          context: %{mode: config.mode, allowed_modes: @allowed_modes}

      is_nil(config.app.path) ->
        raise Error,
          code: :missing_app_path,
          reason: :validation_error,
          context: %{field: :app_path}

      is_nil(config.app.name) ->
        raise Error,
          code: :missing_app_name,
          reason: :validation_error,
          context: %{field: :app_name}

      is_nil(config.app.module) ->
        raise Error,
          code: :missing_app_module,
          reason: :validation_error,
          context: %{field: :app_module}

      is_nil(config.app.otp_app) ->
        raise Error,
          code: :missing_otp_app,
          reason: :validation_error,
          context: %{field: :otp_app}

      !is_list(config.plugins) ->
        raise Error,
          code: :invalid_plugins,
          reason: :validation_error,
          context: %{plugins: config.plugins}

      true ->
        config
    end
  end
end
