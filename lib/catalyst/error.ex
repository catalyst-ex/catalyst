defmodule Catalyst.Error do
  @moduledoc false

  alias Catalyst.ErrorMessages

  defexception [:message, :code, :reason, context: %{}]

  def exception(opts) when is_list(opts) do
    code = Keyword.get(opts, :code, :unknown)
    reason = Keyword.get(opts, :reason)
    context = Keyword.get(opts, :context, %{})
    message = Keyword.get(opts, :message) || ErrorMessages.message(code, context)

    %__MODULE__{message: message, code: code, reason: reason, context: context}
  end
end
