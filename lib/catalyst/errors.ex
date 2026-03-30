defmodule Catalyst.Errors do
  @moduledoc false

  alias Catalyst.ErrorMessages

  def build_exception(module, opts) when is_map(opts),
    do: build_exception(module, Enum.into(opts, []))

  def build_exception(module, opts) when is_list(opts) do
    reason = Keyword.get(opts, :reason, :unknown)
    context = Keyword.get(opts, :context, %{})
    message = Keyword.get(opts, :message) || ErrorMessages.message(reason, context)

    struct(module,
      message: message,
      reason: reason,
      context: context
    )
  end
end

defmodule Catalyst.Errors.ConfigError do
  @moduledoc false

  defexception [:message, :reason, context: %{}]

  def exception(opts), do: Catalyst.Errors.build_exception(__MODULE__, opts)
end

defmodule Catalyst.Errors.PluginError do
  @moduledoc false

  defexception [:message, :reason, context: %{}]

  def exception(opts), do: Catalyst.Errors.build_exception(__MODULE__, opts)
end

defmodule Catalyst.Errors.ActionError do
  @moduledoc false

  defexception [:message, :reason, context: %{}]

  def exception(opts), do: Catalyst.Errors.build_exception(__MODULE__, opts)
end

defmodule Catalyst.Errors.ValidationError do
  @moduledoc false

  defexception [:message, :reason, context: %{}]

  def exception(opts), do: Catalyst.Errors.build_exception(__MODULE__, opts)
end

defmodule Catalyst.Errors.CLIError do
  @moduledoc false

  defexception [:message, :reason, context: %{}]

  def exception(opts), do: Catalyst.Errors.build_exception(__MODULE__, opts)
end

defmodule Catalyst.Errors.ExecutionError do
  @moduledoc false

  defexception [:message, :reason, context: %{}]

  def exception(opts), do: Catalyst.Errors.build_exception(__MODULE__, opts)
end
