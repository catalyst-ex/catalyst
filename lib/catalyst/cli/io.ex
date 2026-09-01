defmodule Catalyst.CLI.IO do
  @moduledoc false

  require Logger

  def info(message) when is_binary(message) do
    Mix.shell().info([:cyan, "info", :reset, " ", message])
  end

  def success(message) when is_binary(message) do
    Mix.shell().info([:green, "ok", :reset, " ", message])
  end

  def warn(message) when is_binary(message) do
    Mix.shell().info([:yellow, "warn", :reset, " ", message])
  end

  def error(message) when is_binary(message) do
    Mix.shell().error([:red, "error", :reset, " ", message])
  end

  def debug(message) when is_binary(message) do
    Logger.debug(message)
  end

  def puts(message) when is_binary(message) do
    Mix.shell().info(message)
  end

  def puts(data) do
    data
    |> inspect()
    |> Mix.shell().info()
  end
end
