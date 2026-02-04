defmodule Catalyst.Action.Executor do
  require Logger
  alias Catalyst.Action

  @doc """
  Dispatches the action to the correct handler.
  """
  def run(%Action.SystemCommand{} = action), do: handle_system_command(action)
  def run(%Action.AddFile{} = action), do: handle_add_file(action)
  def run(%Action.MixTask{} = action), do: handle_mix_task(action)

  # Fallback for unknown actions
  def run(action) do
    Logger.warning("Unknown action encountered: #{inspect(action)}")
    {:error, :unknown_action}
  end

  # --- Handlers ---

  defp handle_system_command(%Action.SystemCommand{cmd: cmd, args: args, env: env, cd: cd}) do
    args = args || []
    env = env || []
    opts = [stderr_to_stdout: true, env: env]
    opts = if cd, do: Keyword.put(opts, :cd, cd), else: opts

    Logger.info("Running: #{cmd} #{Enum.join(args, " ")}")

    case System.cmd(cmd, args, opts) do
      {output, 0} ->
        Logger.debug(output)
        :ok

      {error, code} ->
        raise "Command failed with code #{code}: #{error}"
    end
  end

  defp handle_mix_task(%Action.MixTask{name: task, args: args, env: env}) do
    # Reuse SystemCommand logic to run mix tasks in a separate process
    # This prevents the Mix environment of Catalyst from polluting the target app
    handle_system_command(%Action.SystemCommand{
      cmd: "mix",
      args: [task | args || []],
      env: env
    })
  end

  defp handle_add_file(%Action.AddFile{path: path, content: content}) do
    Logger.info("Creating file: #{path}")

    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
  end
end
