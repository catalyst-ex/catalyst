defmodule Catalyst.ErrorMessages do
  @moduledoc false

  def message(code, context \\ %{})

  def message(:config_file_not_found, %{file_path: file_path}),
    do: "Configuration file not found: #{file_path}"

  def message(:invalid_config_type, %{value: value}),
    do: "Config must be a %Catalyst.Config{} struct, map, or keyword list, got: #{inspect(value)}"

  def message(:invalid_app_config_type, %{value: value}),
    do:
      "Config Error: app must be a %Catalyst.Config.App{} struct, map, or keyword list, got: #{inspect(value)}"

  def message(:invalid_mode, %{allowed_modes: allowed_modes}),
    do: "Config Error: mode must be one of #{inspect(allowed_modes)}"

  def message(:missing_app_path, _), do: "Config Error: app.path is missing"
  def message(:missing_app_name, _), do: "Config Error: app.name is missing"
  def message(:missing_app_module, _), do: "Config Error: app.module is missing"
  def message(:missing_otp_app, _), do: "Config Error: app.otp_app is missing"
  def message(:invalid_plugins, _), do: "Config Error: plugins must be a list"

  def message(:file_not_found, %{path: path}),
    do: "Could not find file to patch: #{path}"

  def message(:missing_config_file, %{path: path}), do: "Config file not found: #{path}"

  def message(:command_failed, %{exit_code: code, output: output}),
    do: "Command failed with code #{code}:\n\n #{output}"

  def message(:unknown_action, %{action: action}),
    do: "Unknown action encountered: #{inspect(action)}"

  def message(:invalid_cli_args, _), do: "Usage: mix catalyst.new <path/to/config.exs>"

  def message(:missing_existing_project, %{path: path}),
    do: "Directory #{path} does not exist. Set app.path to an existing project directory."

  def message(:invalid_existing_project, %{path: path, mix_file: mix_file}),
    do: "Expected Mix project at #{path}, but #{mix_file} was not found."

  def message(:target_path_exists, %{path: path}),
    do:
      "Directory #{path} already exists. Set mode: :existing to run Catalyst on an existing app."

  def message(:phx_scaffold_missing, %{path: path}),
    do:
      "Expected Phoenix scaffold output missing: #{path}. This suggests mix phx.new did not complete."

  def message(:deps_lock_missing, %{path: path}),
    do:
      "Expected dependency lockfile missing: #{path}. This suggests mix deps.get did not complete."

  def message(:invalid_validation_action, %{plugin: plugin, action: action}),
    do:
      "Invalid validation action from #{inspect(plugin)}: #{inspect(action)}. Expected a struct in Catalyst.ValidationAction.action."

  def message(:invalid_post_validate_item, %{plugin: plugin, item: item}),
    do:
      "Invalid post_validate item from #{inspect(plugin)}: #{inspect(item)}. Expected Catalyst.ValidationAction struct."

  def message(:invalid_plugin_spec, %{plugin_spec: plugin_spec}),
    do:
      "Invalid plugin entry: #{inspect(plugin_spec)}. Expected module, {module}, or {module, keyword_opts}."

  def message(:missing_execution_config, _),
    do: "Execution config is missing. Build execution from config via Execution.from_config/1."

  def message(:invalid_execution_config, %{path: path}),
    do: "Execution config is invalid. Missing value at #{inspect(path)}."

  def message(:legacy_execution_fields, %{keys: keys}),
    do:
      "Legacy Execution fields are no longer supported: #{inspect(keys)}. Pass config: ... to Execution.new/1."

  def message(:plugin_execution_failed, %{plugin_run: plugin_run, error: error}) do
    plugin = inspect(plugin_run.plugin)
    "Plugin execution failed in #{plugin}:\n\n#{error}"
  end

  def message(:post_validation_failed, %{validation: validation, error: reason}) do
    plugins =
      validation.plugins
      |> Enum.map(&inspect/1)
      |> Enum.join(", ")

    "Post-validation failed in #{plugins} for #{inspect(validation.action)}:\n\n#{to_string(reason)}"
  end

  def message(code, _context), do: "Catalyst error (#{inspect(code)})"
end
