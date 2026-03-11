defmodule Catalyst.CLI do
  @moduledoc false
  require Logger

  def info(message) when is_binary(message) do
    Owl.IO.puts([Owl.Data.tag("info", :cyan), " ", message])
  end

  def success(message) when is_binary(message) do
    Owl.IO.puts([Owl.Data.tag("ok", :green), " ", message])
  end

  def warn(message) when is_binary(message) do
    Owl.IO.puts([Owl.Data.tag("warn", :yellow), " ", message])
  end

  def error(message) when is_binary(message) do
    Owl.IO.puts([Owl.Data.tag("error", :red), " ", message])
  end

  def debug(message) when is_binary(message) do
    Logger.debug(message)
  end

  def puts(message) when is_binary(message) do
    Owl.IO.puts(message)
  end

  def puts(data) do
    Owl.IO.puts(data)
  end
end
