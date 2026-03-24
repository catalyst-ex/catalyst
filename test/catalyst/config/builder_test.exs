defmodule Catalyst.Config.BuilderTest do
  use ExUnit.Case, async: true

  alias Catalyst.Config
  alias Catalyst.Config.Builder
  alias Catalyst.Error

  test "builds config in :new mode with explicit app identity fields" do
    config =
      Builder.build!(%{
        mode: :new,
        app: %{path: "my_app", name: "my_app", otp_app: :my_app},
        plugins: []
      })

    assert %Config{} = config
    assert config.mode == :new
    assert config.app.path == "my_app"
    assert config.app.name == "my_app"
    assert config.app.module == "MyApp"
    assert config.app.otp_app == :my_app
    assert config.plugins == []
  end

  test "infers :existing mode when app path already exists" do
    base = Path.join(System.tmp_dir!(), "catalyst_tests")
    uniq = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    existing_path = Path.join(base, "existing_app_#{uniq}")

    File.mkdir_p!(existing_path)
    on_exit(fn -> File.rm_rf(existing_path) end)

    config =
      Builder.build!(%{
        app: %{path: existing_path, name: "existing_app", otp_app: :existing_app},
        plugins: []
      })

    assert %Config{} = config
    assert config.mode == :existing
    assert config.app.path == existing_path
    assert is_atom(config.app.otp_app)
    assert config.plugins == []
  end

  test "defaults existing project app path to current directory when identity is provided" do
    config =
      Builder.build!(%Config{
        mode: :existing,
        app: %Config.App{name: "my_app", otp_app: :my_app},
        plugins: []
      })

    assert config.mode == :existing
    assert config.app.path == "."
    assert config.app.name == "my_app"
    assert is_binary(config.app.module)
    assert config.app.otp_app == :my_app
  end

  test "rejects config when app.name is missing" do
    assert_raise Error, ~r/app.name is missing/, fn ->
      Builder.build!(%{
        mode: :new,
        app: %{path: "my_app", module: "MyApp", otp_app: :my_app},
        plugins: []
      })
    end
  end

  test "rejects config when otp_app cannot be derived" do
    assert_raise Error, ~r/app.otp_app is missing/, fn ->
      Builder.build!(%{
        mode: :new,
        app: %{name: "___", path: "___", module: "MyApp"},
        plugins: []
      })
    end
  end

  test "rejects invalid mode" do
    assert_raise Error, ~r/mode must be one of/, fn ->
      Builder.build!(%Config{
        mode: :patch,
        app: %Config.App{path: "my_app", name: "my_app", module: "MyApp"},
        plugins: []
      })
    end
  end
end
