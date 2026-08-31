defmodule Catalyst.Actions.PatchFile do
  @moduledoc """
  Generic action for inserting arbitrary Elixir AST/source into a `.ex` or
  `.exs` file using Sourceror. Handles anything with a `do...end` block -
  `def`/`defp` (guarded or not, block or one-liner), and any other macro
  call that takes a `do:` body (`schema`, `pipeline`, `scope`, etc) - and
  also handles the body itself being a list literal (e.g. a supervisor's
  `children = [...]` or `def children, do: [...]`), splicing into the
  list's elements rather than appending next to it.

  Not intended for `mix.exs` dependency lists - use `AddDependency` for
  that.

  ## Options

    * `:path` - file to patch. Defaults to `Execution.mix_file/1`.
    * `:content` - required. A source string (parsed with
      `Sourceror.parse_string!/1`) or an already-quoted AST fragment.
    * `:target` - where to insert:
        * `nil` (default) - the top level of the file
        * an atom - the body of the first `def`/`defp`/macro call found
          with that name
        * `{:assign, var_name}` - the value of the first `var_name = ...`
          assignment found anywhere in the file
        * a 1-arity function `zipper -> zipper | nil` - custom locator,
          must return a zipper positioned on the block/list/expression to
          patch directly (not a call node, not an assignment node)
    * `:position` - one of:
        * `:end` (default) - append as the last child
        * `:start` - prepend as the first child
        * `:after` / `:before` - needs `:anchor`, a 1-arity function
          receiving each existing child node (raw AST) and returning
          `true` for the node to anchor the insertion to
    * `:anchor` - matcher function, used with `:after` / `:before`

  ## Examples

      # Append a statement into a function body
      run(target: :handle_call, content: "IO.inspect(msg)", position: :start)

      # Append into a list literal body
      run(target: :children, content: "MyApp.NewWorker", position: :end)

      # Append into a variable assigned to a list, e.g. `children = [...]`
      # inside a multi-statement function body
      run(target: {:assign, :children}, content: "MyApp.NewWorker", position: :end)

      # Custom locator - find and splice into a list found anywhere
      run(
        target: fn root_zipper ->
          root_zipper
          |> Zipper.find(fn
            {:=, _, [{:children, _, ctx}, _rhs]} when is_atom(ctx) or is_nil(ctx) -> true
            _ -> false
          end)
          |> case do
            nil -> nil
            assign_zipper -> assign_zipper |> Zipper.down() |> Zipper.right()
          end
        end,
        content: "{MyApp.NewWorker, []}",
        position: :end
      )
  """

  use Catalyst.Action

  alias Catalyst.Shell
  alias Catalyst.Errors.ActionError
  alias Catalyst.Execution
  alias Sourceror.Zipper

  @impl true
  def run(action, execution \\ Execution.new()) when is_list(action) do
    path = Execution.resolve_path(execution, Keyword.get(action, :path))
    content = Keyword.fetch!(action, :content)
    position = Keyword.get(action, :position, :end)
    target = Keyword.get(action, :target)
    node = to_ast(content)

    Shell.info("Patching file: #{path}")

    unless File.exists?(path) do
      raise ActionError,
        reason: :file_not_found,
        context: %{path: path, action: :patch_file}
    end

    source = File.read!(path)
    root_zipper = source |> Sourceror.parse_string!() |> Zipper.zip()

    result = patch(root_zipper, target, node, position, action)

    case result do
      nil ->
        Shell.warn("Could not locate target #{inspect(target)} in #{path}. Skipping.")

      zipper ->
        new_source = zipper |> Zipper.root() |> Sourceror.to_string()

        if new_source != source do
          File.write!(path, [Code.format_string!(new_source), "\n"])
        else
          Shell.warn("No changes made to #{path}")
        end
    end
  end

  defp to_ast(content) when is_binary(content), do: Sourceror.parse_string!(content)
  defp to_ast(content), do: content

  # -- Dispatch on target kind -------------------------------------------

  defp patch(root_zipper, nil, node, position, action) do
    body = Zipper.node(root_zipper)
    Zipper.replace(root_zipper, apply_position(body, node, position, action))
  end

  defp patch(root_zipper, locator, node, position, action) when is_function(locator, 1) do
    case locator.(root_zipper) do
      nil ->
        nil

      zipper ->
        body = Zipper.node(zipper)
        Zipper.replace(zipper, apply_position(body, node, position, action))
    end
  end

  defp patch(root_zipper, target, node, position, action) when is_atom(target) do
    case find_including_self(root_zipper, &target_match?(&1, target)) do
      nil -> nil
      call_zipper -> patch_call(call_zipper, node, position, action)
    end
  end

  # target: [:live_view, :quote] - drill through nested named calls, one
  # level at a time. Finds :live_view first (a def/defp/macro-with-do, same
  # as a single atom target), then searches *within* it for :quote, and so
  # on for as many names as you give. The final match is always a
  # call-with-do-block, so it goes straight to patch_call.
  defp patch(root_zipper, [_ | _] = path, node, position, action) do
    case locate_nested(root_zipper, path) do
      nil -> nil
      found_zipper -> patch_call(found_zipper, node, position, action)
    end
  end

  # target: {:assign, :children} - find `children = <value>` (a plain local
  # variable assignment) anywhere in the file, and splice into the value
  # if it's a list.
  defp patch(root_zipper, {:assign, var_name}, node, position, action) do
    case find_including_self(root_zipper, &assign_match?(&1, var_name)) do
      nil -> nil
      assign_zipper -> patch_assign(assign_zipper, node, position, action)
    end
  end

  # Zipper.find searches forward from the given position, which can skip
  # the starting node itself in some cases - e.g. when the whole file is a
  # single top-level `defmodule`, that node IS the root, so a plain search
  # for :defmodule can come back empty. Check the current node first.
  defp find_including_self(zipper, pred) do
    if pred.(Zipper.node(zipper)) do
      zipper
    else
      Zipper.find(zipper, pred)
    end
  end

  # -- Matching a def/defp/macro-with-do-block by name --------------------

  defp target_match?({:def, _, [head, _]}, target), do: head_name(head) == target
  defp target_match?({:defp, _, [head, _]}, target), do: head_name(head) == target

  defp target_match?({name, _, args}, target) when is_atom(name) and is_list(args),
    do: name == target and has_do_block?(args)

  defp target_match?(_, _), do: false

  defp head_name({:when, _, [inner, _guard]}), do: head_name(inner)
  defp head_name({name, _, _}) when is_atom(name), do: name
  defp head_name(_), do: nil

  defp has_do_block?(args) do
    case List.last(args) do
      kw when is_list(kw) -> Enum.any?(kw, fn {k, _v} -> kw_key(k) == :do end)
      _ -> false
    end
  end

  # Sourceror wraps literal atom values - including keyword keys like `do:`
  # - in `{:__block__, meta, [atom]}` so it can attach comment/formatting
  # metadata. Unwrap either shape down to the plain atom for comparison.
  defp kw_key(key) when is_atom(key), do: key
  defp kw_key({:__block__, _, [key]}) when is_atom(key), do: key
  defp kw_key(_), do: nil

  # Fetch/replace a value by key, tolerating either a plain atom key or
  # Sourceror's block-wrapped form - and, importantly, preserving whichever
  # form the original key was written in when replacing (kw_put keeps `k`
  # as-is, only swapping the value).
  defp kw_fetch(kw, wanted) do
    Enum.find_value(kw, :error, fn {k, v} ->
      if kw_key(k) == wanted, do: {:ok, v}
    end)
  end

  defp kw_put(kw, wanted, new_value) do
    Enum.map(kw, fn {k, v} ->
      if kw_key(k) == wanted, do: {k, new_value}, else: {k, v}
    end)
  end

  defp locate_nested(zipper, [name]), do: find_including_self(zipper, &target_match?(&1, name))

  defp locate_nested(zipper, [name | rest]) do
    case find_including_self(zipper, &target_match?(&1, name)) do
      nil -> nil
      found -> locate_nested(found, rest)
    end
  end

  # -- Finding a variable assignment (e.g. `children = [...]`) -----------

  defp assign_match?({:=, _, [{name, _, ctx}, _rhs]}, var_name)
       when is_atom(name) and (is_atom(ctx) or is_nil(ctx)),
       do: name == var_name

  defp assign_match?(_, _), do: false

  defp patch_assign(assign_zipper, node, position, action) do
    case Zipper.node(assign_zipper) do
      {:=, meta, [lhs, rhs]} ->
        new_rhs = apply_position(rhs, node, position, action)
        Zipper.replace(assign_zipper, {:=, meta, [lhs, new_rhs]})

      _ ->
        nil
    end
  end

  # -- Patching a found call node's :do body -----------------------------

  defp patch_call(call_zipper, node, position, action) do
    case Zipper.node(call_zipper) do
      {tag, meta, args} when is_list(args) ->
        case List.pop_at(args, -1) do
          {kw, rest} when is_list(kw) ->
            case kw_fetch(kw, :do) do
              {:ok, body} ->
                new_body = apply_position(body, node, position, action)
                new_kw = kw_put(kw, :do, new_body)
                Zipper.replace(call_zipper, {tag, meta, rest ++ [new_kw]})

              :error ->
                nil
            end

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  # -- Position/anchor logic, operates on raw AST body -------------------

  defp apply_position(body, node, :end, _action), do: update_body(body, &(&1 ++ [node]))
  defp apply_position(body, node, :start, _action), do: update_body(body, &[node | &1])

  defp apply_position(body, node, :after, action),
    do: splice_body(body, node, :after, Keyword.fetch!(action, :anchor))

  defp apply_position(body, node, :before, action),
    do: splice_body(body, node, :before, Keyword.fetch!(action, :anchor))

  defp update_body(body, f) do
    {kind, meta, children} = unwrap_container(body)
    rewrap_container(kind, meta, f.(children))
  end

  defp splice_body(body, node, rel, matcher) do
    {kind, meta, children} = unwrap_container(body)
    rewrap_container(kind, meta, splice_children(children, node, rel, matcher))
  end

  # A body can be one of four shapes; normalize all of them down to a plain
  # list of "children" to splice, and remember how to rebuild the original
  # shape afterwards.
  #
  #   def foo do              -> block of statements        {:block, ...}
  #     a
  #     b
  #   end
  #
  #   def foo do               -> a block wrapping exactly
  #     [a, b]                    one statement, and that
  #   end                        statement is a list literal  {:list_in_block, ...}
  #
  #   def foo, do: [a, b]      -> the body IS the list, no
  #                                block wrapper at all        {:list, ...}
  #
  #   def foo, do: a           -> single non-list statement    {:single, ...}
  defp unwrap_container({:__block__, meta, [list]}) when is_list(list),
    do: {:list_in_block, meta, list}

  defp unwrap_container({:__block__, meta, children}),
    do: {:block, meta, children}

  defp unwrap_container(list) when is_list(list),
    do: {:list, nil, list}

  defp unwrap_container(single),
    do: {:single, nil, [single]}

  defp rewrap_container(:list_in_block, meta, children), do: {:__block__, meta, [children]}
  defp rewrap_container(:block, meta, children), do: {:__block__, meta, children}
  defp rewrap_container(:list, _meta, children), do: children
  defp rewrap_container(:single, _meta, children), do: {:__block__, [], children}

  defp splice_children(children, node, rel, matcher) do
    case Enum.find_index(children, matcher) do
      nil -> children ++ [node]
      idx when rel == :before -> List.insert_at(children, idx, node)
      idx when rel == :after -> List.insert_at(children, idx + 1, node)
    end
  end
end
