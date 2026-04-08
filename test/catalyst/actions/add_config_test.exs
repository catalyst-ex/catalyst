defmodule Catalyst.Actions.AddConfigTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "AddConfig action tuple exposes expected keys" do
    {mod, opts} =
      {Actions.AddConfig,
       app: :my_app, module: MyApp.Repo, opts: [url: "ecto://localhost/my_app"]}

    expected_keys = [:app, :module, :opts] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.AddConfig
    assert actual_keys == expected_keys
  end

  test "AddConfig action can be represented as tuple" do
    {mod, opts} =
      {Actions.AddConfig,
       app: :my_app, module: MyApp.Repo, opts: [url: "ecto://localhost/my_app"]}

    assert mod == Actions.AddConfig
    assert Keyword.fetch!(opts, :app) == :my_app
    assert Keyword.fetch!(opts, :module) == MyApp.Repo
    assert Keyword.fetch!(opts, :opts) == [url: "ecto://localhost/my_app"]
  end
end
