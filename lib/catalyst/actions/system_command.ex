defmodule Catalyst.Actions.SystemCommand do
  alias Catalyst.CLI

  defstruct [:cmd, :args, :env, :cd]

  def execute(%__MODULE__{cmd: cmd, args: args, env: env, cd: cd}) do
    args = args || []
    env = env || []
    opts = [stderr_to_stdout: true, env: env]
    opts = if cd, do: Keyword.put(opts, :cd, cd), else: opts

    CLI.info("Running: #{cmd} #{Enum.join(args, " ")}")

    case System.cmd(cmd, args, opts) do
      {output, 0} ->
        CLI.debug(output)
        :ok

      {error, code} ->
        if allow_nonzero_exit?(cmd, args, error) do
          CLI.warn(
            "Command exited with code #{code} but was allowed: #{cmd} #{Enum.join(args, " ")}"
          )

          CLI.debug(error)
          :ok
        else
          raise "Command failed with code #{code}:\n\n #{error}"
        end
    end
  end

  defp allow_nonzero_exit?("mix", ["quality" | _], output) do
    String.contains?(output, "SCAN COMPLETE")
  end

  defp allow_nonzero_exit?(_cmd, _args, _output), do: false
end
