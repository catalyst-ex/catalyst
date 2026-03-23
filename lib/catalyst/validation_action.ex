defmodule Catalyst.ValidationAction do
  @moduledoc """
  Declares a post-validation action.
  """

  alias Catalyst.Actions

  @type t :: %__MODULE__{
          action: Actions.t(),
          required: boolean(),
          reuse_existing: boolean(),
          plugins: [module()]
        }

  defstruct action: nil,
            required: true,
            reuse_existing: true,
            plugins: []
end
