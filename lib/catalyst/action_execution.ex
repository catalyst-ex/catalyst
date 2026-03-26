defmodule Catalyst.ActionExecution do
  @moduledoc false

  defstruct [
    :action,
    :plugin,
    :plugins,
    :phase,
    :required,
    :status,
    :result,
    :error
  ]

  def new(attrs \\ %{}) when is_map(attrs) do
    struct(__MODULE__, attrs)
  end
end
