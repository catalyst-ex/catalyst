defmodule Catalyst.Actions.SystemCommand do
  use Catalyst.Action

  alias Catalyst.CLI
  alias Catalyst.Errors.ActionError

  @impl true
  def run(action, _execution \\ nil) when is_list(action) do
    cmd = Keyword.fetch!(action, :cmd)
    args = Keyword.get(action, :args, [])
    env = Keyword.get(action, :env, [])
    cd = Keyword.get(action, :cd)

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
          raise ActionError,
            reason: :command_failed,
            context: %{cmd: cmd, args: args, exit_code: code, output: error}
        end
    end
  end

  defp allow_nonzero_exit?("mix", ["quality" | _], output) do
    String.contains?(output, "SCAN COMPLETE")
  end

  defp allow_nonzero_exit?(_cmd, _args, _output), do: false
end
