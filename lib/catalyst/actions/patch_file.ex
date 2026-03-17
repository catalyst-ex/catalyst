defmodule Catalyst.Actions.PatchFile do
  defstruct [:path, :ops]

  @type t :: %__MODULE__{
          path: Path.t() | nil,
          ops: [term()] | nil
        }
end
