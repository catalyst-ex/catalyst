defmodule Catalyst.Config.Loader do
  alias Catalyst.Config.Builder
  alias Catalyst.Error

  @doc """
  Reads an Elixir script file and expects it to return a config definition
  that can be normalized by Catalyst.Config.Builder.
  """
  def load!(file_path) do
    # Verify file exists
    unless File.exists?(file_path) do
      raise Error,
        code: :config_file_not_found,
        reason: :not_found,
        context: %{file_path: file_path}
    end

    # Evaluate the file
    # We bind nothing to the context to keep it clean.
    {result, _bindings} = Code.eval_file(file_path)

    Builder.build!(result)
  end
end
