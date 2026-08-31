defmodule Catalyst.CLITest do
  use ExUnit.Case, async: true

  test "defines the CLI namespace" do
    assert Code.ensure_loaded?(Catalyst.CLI)
  end
end
