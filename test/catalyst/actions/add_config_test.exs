defmodule Catalyst.Actions.AddConfigTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "AddConfig exposes expected keys" do
    expected_keys = [:__struct__, :app, :module, :opts] |> Enum.sort()
    actual_keys = Actions.AddConfig.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AddConfig can be instantiated" do
    action =
      struct(Actions.AddConfig,
        app: :my_app,
        module: MyApp.Repo,
        opts: [url: "ecto://localhost/my_app"]
      )

    assert %Actions.AddConfig{} = action
    assert action.app == :my_app
    assert action.module == MyApp.Repo
    assert action.opts == [url: "ecto://localhost/my_app"]
  end
end
