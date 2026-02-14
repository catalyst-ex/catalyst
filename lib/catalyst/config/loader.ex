defmodule Catalyst.Config.Loader do
  alias Catalyst.Config

  @doc """
  Reads an Elixir script file and expects it to return a %Catalyst.Config{} struct.
  """
  def load!(file_path) do
    # Verify file exists
    unless File.exists?(file_path) do
      raise "Configuration file not found: #{file_path}"
    end

    # Evaluate the file
    # We bind nothing to the context to keep it clean.
    {result, _bindings} = Code.eval_file(file_path)

    # Validate the result
    case result do
      %Config{} = config ->
        validate_config!(config)

      _ ->
        raise "File #{file_path} must return a %Catalyst.Config{} struct, got: #{inspect(result)}"
    end
  end

  defp validate_config!(config) do
    # Basic validation: Ensure required fields are present
    cond do
      is_nil(config.app.name) -> raise "Config Error: app.name is missing"
      is_nil(config.app.path) -> raise "Config Error: app.path is missing"
      is_nil(config.app.module) -> raise "Config Error: app.module is missing"
      !is_list(config.plugins) -> raise "Config Error: plugins must be a list"
      true -> config
    end
  end
end
