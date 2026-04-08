defmodule Catalyst.Actions do
  @moduledoc false

  @type t :: {module(), keyword()}

  # Returns a stable identity key for an action.
  # Keys are used to compare actions for dedupe/reuse across phases.
  def key({Catalyst.Actions.MixTask, opts}) when is_list(opts),
    do: {:mix_task, Keyword.get(opts, :name), Keyword.get(opts, :args, [])}

  def key({Catalyst.Actions.SystemCommand, opts}) when is_list(opts),
    do: {:system_command, Keyword.get(opts, :cmd), Keyword.get(opts, :args, [])}

  def key({type, payload}) when is_atom(type) and is_list(payload),
    do: {type, normalize_keyword(payload)}

  def key(action), do: action

  defp normalize_keyword(keyword) when is_list(keyword) do
    if Keyword.keyword?(keyword) do
      keyword
      |> Enum.sort_by(fn {key, _value} -> key end)
      |> Enum.map(fn {key, value} -> {key, normalize_value(value)} end)
    else
      Enum.map(keyword, &normalize_value/1)
    end
  end

  defp normalize_value(value) when is_list(value), do: normalize_keyword(value)
  defp normalize_value(value), do: value
end
