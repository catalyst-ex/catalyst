defmodule Catalyst.PluginOptionParserTest do
  use ExUnit.Case, async: true

  alias Catalyst.Errors.PluginError
  alias Catalyst.Plugin
  alias Catalyst.PluginOptionParser
  alias Catalyst.Plugins.PhoenixBase

  defmodule ThirdPartyPlugin do
    use Plugin

    @impl true
    def run(_execution, _opts), do: []
  end

  defmodule PluginWithDefaults do
    use Plugin

    @impl true
    def opts_schema, do: [color: [type: :string, default: "blue"]]

    @impl true
    def run(_execution, _opts), do: []
  end

  defmodule PluginWithRequired do
    use Plugin

    @impl true
    def opts_schema, do: [token: [type: :string, required: true]]

    @impl true
    def run(_execution, _opts), do: []
  end

  defmodule PluginInitReturnsError do
    use Plugin

    @impl true
    def init(_opts, _config), do: {:error, :bad_opts}

    @impl true
    def run(_execution, _opts), do: []
  end

  defmodule PluginInitReturnsNonKeyword do
    use Plugin

    @impl true
    def init(_opts, _config), do: {:ok, %{not: :keyword}}

    @impl true
    def run(_execution, _opts), do: []
  end

  defmodule PluginWithOneOf do
    use Plugin

    @impl true
    def run(_execution, _opts), do: []
  end

  defmodule PluginWithMalformedSchema do
    use Plugin

    @impl true
    def opts_schema, do: [{"bad", [type: :string]}]

    @impl true
    def run(_execution, _opts), do: []
  end

  test "accepts phoenix version option for PhoenixBase" do
    opts = [phoenix: "1.18.4", flags: [install: false, ecto: false, mailer: false]]

    assert Keyword.keyword?(PluginOptionParser.validate!(PhoenixBase, opts, %{}))
  end

  test "parse returns invalid for unknown option in strict mode" do
    opts = [phoenix: "1.18.4", unknown: true]

    {parsed, rest, invalid} =
      PluginOptionParser.parse(PhoenixBase, opts, %{}, strict: [phoenix: :string])

    assert parsed == [phoenix: "1.18.4"]
    assert rest == []

    assert [
             %{
               kind: :unknown_option,
               plugin: PhoenixBase,
               option: :unknown,
               value: true,
               allowed_keys: [:phoenix]
             }
           ] = invalid
  end

  test "parse returns invalid_type payload contract" do
    opts = [phoenix: 123]

    {parsed, rest, invalid} =
      PluginOptionParser.parse(PhoenixBase, opts, %{}, strict: [phoenix: :string])

    assert parsed == []
    assert rest == []

    assert [
             %{
               kind: :invalid_type,
               plugin: PhoenixBase,
               option: :phoenix,
               expected_type: :string,
               value: 123
             }
           ] = invalid
  end

  test "parse keeps unknown option in switches mode" do
    opts = [phoenix: "1.18.4", unknown: true]

    {parsed, rest, invalid} =
      PluginOptionParser.parse(PhoenixBase, opts, %{}, switches: [phoenix: :string])

    assert Keyword.get(parsed, :phoenix) == "1.18.4"
    assert Keyword.get(parsed, :unknown) == true
    assert rest == []
    assert invalid == []
  end

  test "parse supports aliases" do
    opts = [phx: "1.18.4"]

    {parsed, rest, invalid} =
      PluginOptionParser.parse(PhoenixBase, opts, %{}, aliases: [phx: :phoenix])

    assert Keyword.get(parsed, :phoenix) == "1.18.4"
    assert Keyword.get(parsed, :flags) == []
    assert rest == []
    assert invalid == []
  end

  test "parse overrides duplicate values by default" do
    opts = [phoenix: "1.18.4", phoenix: "1.18.5"]

    {parsed, rest, invalid} = PluginOptionParser.parse(PhoenixBase, opts, %{})

    assert Keyword.get(parsed, :phoenix) == "1.18.5"
    assert rest == []
    assert invalid == []
  end

  test "parse keeps duplicate values with keep modifier" do
    opts = [phoenix: "1.18.4", phoenix: "1.18.5"]

    {parsed, rest, invalid} =
      PluginOptionParser.parse(PhoenixBase, opts, %{}, strict: [phoenix: [:string, :keep]])

    assert Keyword.get_values(parsed, :phoenix) == ["1.18.4", "1.18.5"]
    assert rest == []
    assert invalid == []
  end

  test "allows options for plugin without schema" do
    opts = [custom: :value, anything: [nested: true]]
    parsed = PluginOptionParser.validate!(ThirdPartyPlugin, opts, %{})

    assert Keyword.get(parsed, :custom) == :value
    assert Keyword.get(parsed, :anything) == [nested: true]
  end

  test "strict and switches together raises ArgumentError" do
    assert_raise ArgumentError, "Only one of :strict or :switches may be provided", fn ->
      PluginOptionParser.parse(PhoenixBase, [phoenix: "1.18.4"], %{},
        strict: [phoenix: :string],
        switches: [phoenix: :string]
      )
    end
  end

  test "parse with non-keyword opts returns invalid_opts_type" do
    opts = %{phoenix: "1.18.4"}

    assert {[], [], [%{kind: :invalid_opts_type, plugin: PhoenixBase, opts: ^opts}]} =
             PluginOptionParser.parse(PhoenixBase, opts, %{})
  end

  test "validate! with non-keyword opts raises PluginError reason invalid_plugin_opts" do
    opts = %{phoenix: "1.18.4"}

    error =
      assert_raise PluginError, fn ->
        PluginOptionParser.validate!(PhoenixBase, opts, %{})
      end

    assert error.reason == :invalid_plugin_opts
    assert error.context.plugin == PhoenixBase
  end

  test "strict rules apply default value" do
    {parsed, rest, invalid} =
      PluginOptionParser.parse(PluginWithDefaults, [], %{},
        strict: [color: [type: :string, default: "blue"]]
      )

    assert parsed == [color: "blue"]
    assert rest == []
    assert invalid == []
  end

  test "strict rules report missing_required" do
    {parsed, rest, invalid} =
      PluginOptionParser.parse(PluginWithRequired, [], %{},
        strict: [token: [type: :string, required: true]]
      )

    assert parsed == []
    assert rest == []
    assert [%{kind: :missing_required, plugin: PluginWithRequired, option: :token}] = invalid
  end

  test "switches mode allows unknown even when plugin schema exists" do
    {parsed, rest, invalid} =
      PluginOptionParser.parse(PhoenixBase, [phoenix: "1.18.4", surprise: true], %{},
        switches: [phoenix: :string]
      )

    assert Keyword.get(parsed, :phoenix) == "1.18.4"
    assert Keyword.get(parsed, :surprise) == true
    assert rest == []
    assert invalid == []
  end

  test "malformed opts_schema raises PluginError" do
    error =
      assert_raise PluginError, fn ->
        PluginOptionParser.parse(PluginWithMalformedSchema, [any: true], %{})
      end

    assert error.reason == :invalid_plugin_opts
    assert error.context.plugin == PluginWithMalformedSchema
  end

  test "init/2 returning error tuple raises PluginError" do
    error =
      assert_raise PluginError, fn ->
        PluginOptionParser.parse(PluginInitReturnsError, [any: true], %{})
      end

    assert error.reason == :invalid_plugin_opts
    assert error.context.plugin == PluginInitReturnsError
  end

  test "init/2 returning non-keyword ok tuple raises PluginError" do
    error =
      assert_raise PluginError, fn ->
        PluginOptionParser.parse(PluginInitReturnsNonKeyword, [any: true], %{})
      end

    assert error.reason == :invalid_plugin_opts
    assert error.context.plugin == PluginInitReturnsNonKeyword
  end

  test "one_of accepts atom and string" do
    {parsed_atom, rest_atom, invalid_atom} =
      PluginOptionParser.parse(PluginWithOneOf, [choice: :ok], %{},
        strict: [choice: [type: {:one_of, [:atom, :string]}]]
      )

    {parsed_string, rest_string, invalid_string} =
      PluginOptionParser.parse(PluginWithOneOf, [choice: "ok"], %{},
        strict: [choice: [type: {:one_of, [:atom, :string]}]]
      )

    assert parsed_atom == [choice: :ok]
    assert rest_atom == []
    assert invalid_atom == []

    assert parsed_string == [choice: "ok"]
    assert rest_string == []
    assert invalid_string == []
  end

  test "one_of rejects integer and yields invalid_type entry" do
    {parsed, rest, invalid} =
      PluginOptionParser.parse(PluginWithOneOf, [choice: 123], %{},
        strict: [choice: [type: {:one_of, [:atom, :string]}]]
      )

    assert parsed == []
    assert rest == []

    assert [
             %{
               kind: :invalid_type,
               plugin: PluginWithOneOf,
               option: :choice,
               expected_type: {:one_of, [:atom, :string]},
               value: 123
             }
           ] = invalid
  end
end
