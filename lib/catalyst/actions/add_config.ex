defmodule Catalyst.Actions.AddConfig do
  use Catalyst.Action

  alias Catalyst.Shell
  alias Catalyst.Errors.ActionError
  alias Catalyst.Execution

  @impl true
  def run(action, execution \\ Execution.new()) when is_list(action) do
    file_name = Keyword.get(action, :config_file) || "config.exs"
    path = Execution.config_file(execution, file_name)
    app = Keyword.get(action, :app) || Execution.otp_app(execution)
    mod = Keyword.get(action, :module)
    opts = Keyword.fetch!(action, :opts)

    Shell.info("Configuring: #{inspect(app)} #{if mod, do: inspect(mod)}")

    unless File.exists?(path) do
      raise ActionError,
        reason: :file_not_found,
        context: %{path: path}
    end

    source = File.read!(path)
    zipper = source |> Sourceror.parse_string!() |> Sourceror.Zipper.zip()

    if config_exists?(zipper, app, mod) do
      Shell.info("   ↳ Config already exists, skipping.")
    else
      new_ast = build_config_ast(app, mod, opts)

      new_zipper =
        case find_import_config(zipper) do
          nil -> Sourceror.Zipper.append_child(zipper, new_ast)
          import_zipper -> Sourceror.Zipper.insert_left(import_zipper, new_ast)
        end

      new_source = new_zipper |> Sourceror.Zipper.root() |> Sourceror.to_string()
      formatted = Code.format_string!(new_source)
      File.write!(path, formatted)
    end
  end

  defp config_exists?(zipper, app, mod) do
    found =
      Sourceror.Zipper.find(zipper, fn
        {:config, _, [^app, ^mod, _]} -> true
        {:config, _, [^app, _]} when is_nil(mod) -> true
        _ -> false
      end)

    found != nil
  end

  defp find_import_config(zipper) do
    Sourceror.Zipper.find(zipper, fn
      {:import_config, _, _} -> true
      _ -> false
    end)
  end

  defp build_config_ast(app, nil, opts) do
    quote do
      config unquote(app), unquote(opts)
    end
  end

  defp build_config_ast(app, mod, opts) do
    quote do
      config unquote(app), unquote(mod), unquote(opts)
    end
  end
end
