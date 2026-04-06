defmodule Catalyst.PluginOptionParser do
  @moduledoc """
  Parses and validates plugin options using OptionParser-like semantics.

  This module supports two primary flows:

  - `parse/4`: non-raising parse that returns `{parsed, rest, invalid}`
  - `validate!/3`: raising validation helper used by runtime planner code

  Parsing mode is selected in this order:

  1. `:strict` passed to `parse/4`
  2. `:switches` passed to `parse/4`
  3. plugin `opts_schema/0` when available
  4. permissive `:switches` mode when no schema is declared

  ## Return Shape

  `parse/4` always returns a tuple in the shape:

      {parsed_opts, [], invalid_entries}

  Where:

  - `parsed_opts` is a keyword list of accepted options
  - `[]` is the rest slot kept for OptionParser-style compatibility
  - `invalid_entries` is a list of maps with a `:kind` key, for example:
    - `%{kind: :unknown_option, ...}`
    - `%{kind: :invalid_type, ...}`
    - `%{kind: :missing_required, ...}`
    - `%{kind: :invalid_opts_type, ...}`

  ## Duplicate Options

  By default, repeated keys are overwritten (last value wins).
  Use `:keep` in a rule to preserve repeated entries.

  ## Errors

  `validate!/3` raises `Catalyst.Errors.PluginError` with reason
  `:invalid_plugin_opts` when parsing or schema validation fails.
  """

  alias Catalyst.Errors.PluginError

  @default_sentinel :__catalyst_no_default__

  @type parsed :: keyword()
  @type invalid_kind :: :unknown_option | :invalid_type | :missing_required | :invalid_opts_type
  @type invalid_entry :: %{required(:kind) => invalid_kind(), optional(atom()) => any()}
  @type parse_result :: {parsed(), [], [invalid_entry()]}
  @type parser_options :: [strict: keyword(), switches: keyword(), aliases: keyword()]

  # Parses plugin options and returns OptionParser-like `{parsed, rest, invalid}`.
  @doc """
  Parses plugin options without raising.

  Accepts raw plugin options, runs plugin `init/2` normalization, applies aliases,
  and validates against strict or switches rules.

  ## Parameters

  - `plugin_mod`: plugin module implementing `init/2`
  - `opts`: input keyword options
  - `config`: project/runtime config passed through to `init/2`
  - `parser_opts`: parser overrides such as `strict:`, `switches:`, `aliases:`

  ## Returns

      {parsed_opts, [], invalid_entries}

  This function does not raise for unknown/type/required-option parse failures;
  they are returned in `invalid_entries`.

  It may still raise `Catalyst.Errors.PluginError` if `init/2` returns an invalid
  shape or if schema declaration itself is malformed.
  """
  @spec parse(module(), keyword(), map(), parser_options()) :: parse_result()
  def parse(plugin_mod, opts, config, parser_opts \\ [])

  def parse(plugin_mod, opts, config, parser_opts)
      when is_atom(plugin_mod) and is_list(opts) and is_list(parser_opts) do
    normalized_opts = normalize_with_init!(plugin_mod, opts, config)
    {mode, schema} = resolve_mode_and_schema(plugin_mod, parser_opts)
    aliased_opts = apply_aliases(normalized_opts, Keyword.get(parser_opts, :aliases, []))

    validate_schema_shape!(plugin_mod, schema)
    {parsed_opts, invalid} = parse_opts(plugin_mod, aliased_opts, schema, mode)

    {parsed_opts, [], invalid}
  end

  def parse(plugin_mod, opts, _config, _parser_opts) do
    invalid = [invalid_entry(:invalid_opts_type, %{plugin: plugin_mod, opts: opts})]
    {[], [], invalid}
  end

  @doc """
  Validates plugin options and returns parsed options or raises.

  This is a strict helper around `parse/4` that converts the first invalid parse
  entry into a `Catalyst.Errors.PluginError`.

  ## Returns

  - parsed keyword options when validation succeeds

  ## Raises

  - `Catalyst.Errors.PluginError` when options are invalid, missing required keys,
    contain unknown keys in strict mode, have invalid types, or are not a keyword list
  """
  @spec validate!(module(), keyword(), map()) :: keyword()
  def validate!(plugin_mod, opts, config) when is_atom(plugin_mod) and is_list(opts) do
    {parsed_opts, [], invalid} = parse(plugin_mod, opts, config)

    case invalid do
      [] ->
        parsed_opts

      [first | _] ->
        raise_from_invalid!(plugin_mod, opts, first)
    end
  end

  def validate!(plugin_mod, opts, _config) do
    raise PluginError,
      reason: :invalid_plugin_opts,
      context: %{
        plugin: plugin_mod,
        opts: opts,
        detail: "Plugin options must be a keyword list."
      }
  end

  # Parse internals
  defp apply_aliases(opts, aliases) when is_list(aliases) do
    Enum.map(opts, fn {key, value} ->
      canonical_key = Keyword.get(aliases, key, key)
      {canonical_key, value}
    end)
  end

  defp resolve_mode_and_schema(plugin_mod, parser_opts) do
    strict = Keyword.get(parser_opts, :strict)
    switches = Keyword.get(parser_opts, :switches)
    schema = schema_for(plugin_mod)

    if strict != nil and switches != nil do
      raise ArgumentError, "Only one of :strict or :switches may be provided"
    end

    cond do
      is_list(strict) -> {:strict, normalize_schema(strict)}
      is_list(switches) -> {:switches, normalize_schema(switches)}
      schema == [] -> {:switches, []}
      true -> {:strict, normalize_schema(schema)}
    end
  end

  defp parse_opts(plugin_mod, opts, schema, mode) do
    allowed_keys = schema |> Keyword.keys() |> MapSet.new()

    {parsed_opts, invalid} =
      Enum.reduce(opts, {[], []}, fn {key, value}, {parsed_acc, invalid_acc} ->
        cond do
          MapSet.member?(allowed_keys, key) ->
            rules = Keyword.fetch!(schema, key)
            {type, keep?} = rules_type_and_keep(rules)

            if valid_type?(value, type) do
              {put_parsed_option(parsed_acc, key, value, keep?), invalid_acc}
            else
              entry =
                invalid_entry(:invalid_type, %{
                  plugin: plugin_mod,
                  option: key,
                  expected_type: type,
                  value: value
                })

              {parsed_acc, invalid_acc ++ [entry]}
            end

          mode == :switches ->
            {put_parsed_option(parsed_acc, key, value, false), invalid_acc}

          true ->
            entry =
              invalid_entry(:unknown_option, %{
                plugin: plugin_mod,
                option: key,
                value: value,
                allowed_keys: Keyword.keys(schema)
              })

            {parsed_acc, invalid_acc ++ [entry]}
        end
      end)

    apply_defaults_and_required(plugin_mod, parsed_opts, schema, invalid)
  end

  defp put_parsed_option(parsed_opts, key, value, true), do: parsed_opts ++ [{key, value}]

  defp put_parsed_option(parsed_opts, key, value, false) do
    if Keyword.has_key?(parsed_opts, key) do
      Enum.map(parsed_opts, fn
        {^key, _existing} -> {key, value}
        entry -> entry
      end)
    else
      parsed_opts ++ [{key, value}]
    end
  end

  defp apply_defaults_and_required(plugin_mod, parsed_opts, schema, invalid) do
    Enum.reduce(schema, {parsed_opts, invalid}, fn {key, rules}, {opts_acc, invalid_acc} ->
      required? = Keyword.get(rules, :required, false)
      default = Keyword.get(rules, :default, @default_sentinel)

      case Keyword.fetch(opts_acc, key) do
        {:ok, _value} ->
          {opts_acc, invalid_acc}

        :error when default != @default_sentinel ->
          {Keyword.put(opts_acc, key, default), invalid_acc}

        :error when required? ->
          entry =
            invalid_entry(:missing_required, %{
              plugin: plugin_mod,
              option: key
            })

          {opts_acc, invalid_acc ++ [entry]}

        :error ->
          {opts_acc, invalid_acc}
      end
    end)
  end

  defp invalid_entry(kind, payload), do: Map.put(payload, :kind, kind)

  # Validation internals
  defp raise_from_invalid!(plugin_mod, opts, %{kind: :unknown_option, option: _} = invalid) do
    unknown_keys =
      invalid
      |> Map.fetch!(:option)
      |> List.wrap()

    raise PluginError,
      reason: :invalid_plugin_opts,
      context: %{
        plugin: plugin_mod,
        opts: opts,
        unknown_keys: unknown_keys,
        allowed_keys: Map.get(invalid, :allowed_keys, [])
      }
  end

  defp raise_from_invalid!(plugin_mod, _opts, %{kind: :invalid_type} = invalid) do
    raise PluginError,
      reason: :invalid_plugin_opts,
      context: %{
        plugin: plugin_mod,
        option: invalid.option,
        expected_type: invalid.expected_type,
        value: invalid.value
      }
  end

  defp raise_from_invalid!(plugin_mod, opts, %{kind: :missing_required} = invalid) do
    raise PluginError,
      reason: :invalid_plugin_opts,
      context: %{
        plugin: plugin_mod,
        opts: opts,
        missing_key: invalid.option
      }
  end

  defp raise_from_invalid!(plugin_mod, opts, %{kind: :invalid_opts_type}) do
    raise PluginError,
      reason: :invalid_plugin_opts,
      context: %{
        plugin: plugin_mod,
        opts: opts,
        detail: "Plugin options must be a keyword list."
      }
  end

  defp raise_from_invalid!(plugin_mod, opts, invalid) do
    raise PluginError,
      reason: :invalid_plugin_opts,
      context: %{
        plugin: plugin_mod,
        opts: opts,
        detail: "Invalid plugin option: #{inspect(invalid)}"
      }
  end

  # Plugin adapter internals
  defp normalize_with_init!(plugin_mod, opts, config) do
    case plugin_mod.init(opts, config) do
      {:ok, normalized_opts} ->
        if is_list(normalized_opts) and Keyword.keyword?(normalized_opts) do
          normalized_opts
        else
          raise PluginError,
            reason: :invalid_plugin_opts,
            context: %{
              plugin: plugin_mod,
              opts: opts,
              detail:
                "Plugin init/2 must return {:ok, keyword_opts}. Got: #{inspect(normalized_opts)}"
            }
        end

      {:error, reason} ->
        raise PluginError,
          reason: :invalid_plugin_opts,
          context: %{
            plugin: plugin_mod,
            opts: opts,
            detail: "Plugin init/2 rejected options: #{inspect(reason)}"
          }

      other ->
        raise PluginError,
          reason: :invalid_plugin_opts,
          context: %{
            plugin: plugin_mod,
            opts: opts,
            detail:
              "Plugin init/2 must return {:ok, keyword_opts} or {:error, reason}. Got: #{inspect(other)}"
          }
    end
  end

  defp schema_for(plugin_mod) do
    if function_exported?(plugin_mod, :opts_schema, 0), do: plugin_mod.opts_schema(), else: []
  end

  defp validate_schema_shape!(plugin_mod, schema) when is_list(schema) do
    Enum.each(schema, fn
      {key, rules} when is_atom(key) ->
        validate_rules_shape!(plugin_mod, key, rules)

      invalid ->
        raise PluginError,
          reason: :invalid_plugin_opts,
          context: %{
            plugin: plugin_mod,
            detail: "Invalid opts_schema entry: #{inspect(invalid)}"
          }
    end)

    :ok
  end

  defp validate_rules_shape!(_plugin_mod, _key, rules) when is_list(rules), do: :ok

  defp validate_rules_shape!(plugin_mod, key, rules) do
    raise PluginError,
      reason: :invalid_plugin_opts,
      context: %{
        plugin: plugin_mod,
        detail: "Invalid opts_schema rules for #{inspect(key)}: #{inspect(rules)}"
      }
  end

  # Rule engine internals
  defp normalize_schema(schema) do
    Enum.map(schema, fn {key, rules} ->
      {key, normalize_rules(rules)}
    end)
  end

  defp rules_type_and_keep(rules) when is_list(rules) do
    if Keyword.keyword?(rules) do
      type = Keyword.get(rules, :type, :any)
      keep? = keep_modifier?(rules, type)
      {normalize_type(type), keep?}
    else
      keep? = :keep in rules
      types = Enum.reject(rules, &(&1 == :keep))

      type =
        case types do
          [] -> :string
          [single] -> single
          _ -> {:one_of, types}
        end

      {normalize_type(type), keep?}
    end
  end

  defp rules_type_and_keep(type), do: {normalize_type(type), false}

  defp valid_type?(_value, :any), do: true
  defp valid_type?(value, :boolean), do: is_boolean(value)
  defp valid_type?(value, :atom), do: is_atom(value)
  defp valid_type?(value, :string), do: is_binary(value)
  defp valid_type?(value, :integer), do: is_integer(value)
  defp valid_type?(value, :float), do: is_float(value)
  defp valid_type?(value, :list), do: is_list(value)
  defp valid_type?(value, :map), do: is_map(value)
  defp valid_type?(value, :keyword), do: is_list(value) and Keyword.keyword?(value)

  defp valid_type?(value, {:one_of, types}) when is_list(types) do
    Enum.any?(types, &valid_type?(value, &1))
  end

  defp valid_type?(_value, _type), do: false

  defp normalize_rules(rules) when is_list(rules), do: rules
  defp normalize_rules(type), do: [type: type]

  defp keep_modifier?(rules, type) do
    case Keyword.fetch(rules, :keep) do
      {:ok, keep?} -> keep?
      :error -> is_list(type) and :keep in type
    end
  end

  defp normalize_type(type) when is_list(type) do
    normalized = Enum.reject(type, &(&1 == :keep))

    case normalized do
      [] -> :string
      [single] -> single
      _ -> {:one_of, normalized}
    end
  end

  defp normalize_type(type), do: type
end
