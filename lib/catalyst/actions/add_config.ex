defmodule Catalyst.Actions.AddConfig do
  alias Catalyst.CLI

  defstruct [:target_file, :app, :module, :opts]

  @type t :: %__MODULE__{
          target_file: Path.t() | nil,
          app: atom() | nil,
          module: module() | nil,
          opts: keyword() | nil
        }

  def execute(%__MODULE__{target_file: path} = action) do
    CLI.info(
      "Configuring: #{inspect(action.app)} #{if action.module, do: inspect(action.module)}"
    )

    unless File.exists?(path), do: raise("Config file not found: #{path}")

    source = File.read!(path)
    zipper = source |> Sourceror.parse_string!() |> Sourceror.Zipper.zip()

    if config_exists?(zipper, action.app, action.module) do
      CLI.info("   ↳ Config already exists, skipping.")
    else
      new_ast = build_config_ast(action.app, action.module, action.opts)

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
