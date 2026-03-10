defmodule Catalyst.Config.BuilderTest do
  use ExUnit.Case, async: true

  alias Catalyst.Config
  alias Catalyst.Config.Builder

  test "builds config from map and infers app defaults" do
    config =
      Builder.build!(%{
        app: %{path: "my_app"},
        plugins: []
      })

    assert %Config{} = config
    assert config.mode == :new
    assert config.app.path == "my_app"
    assert config.app.name == "my_app"
    assert config.app.module == "MyApp"
    assert config.plugins == []
  end

  test "defaults existing project app path to current directory" do
    config =
      Builder.build!(%Config{
        mode: :existing,
        app: %Config.App{},
        plugins: []
      })

    assert config.mode == :existing
    assert config.app.path == "."
    assert is_binary(config.app.name)
    assert is_binary(config.app.module)
  end

  test "rejects invalid mode" do
    assert_raise RuntimeError, ~r/mode must be one of/, fn ->
      Builder.build!(%Config{
        mode: :patch,
        app: %Config.App{path: "my_app", name: "my_app", module: "MyApp"},
        plugins: []
      })
    end
  end
end
