defmodule Catalyst do
  @moduledoc """
  Main entry point for Catalyst. Orchestrates the execution of plugins, actions, and validations.
  """

  alias Catalyst.ActionRunner
  alias Catalyst.CLI
  alias Catalyst.Execution
  alias Catalyst.PluginPlanner
  alias Catalyst.ValidationPipeline

  def build(config) do
    execution = Execution.from_config(config)

    # collect plugins actions and post-validations
    {execution, action_entries, post_validations} =
      PluginPlanner.collect(config.plugins, execution)

    # execute collected run actions, then post validations
    {execution, executed_actions} = ActionRunner.run(action_entries, execution)

    # execute post-validations
    execution = run_post_validations(post_validations, executed_actions, execution)

    {:ok, execution}
  end

  # -- Helpers --

  defp run_post_validations(validations, existing_actions, execution) do
    {warnings, execution} = ValidationPipeline.run(validations, existing_actions, execution)

    maybe_print_validation_summary(warnings)
    execution
  end

  defp maybe_print_validation_summary([]), do: :ok

  defp maybe_print_validation_summary(warnings) do
    details = warnings |> Enum.map(&("- " <> &1)) |> Enum.join("\n\n")

    CLI.warn("Optional post-validations reported issues:\n\n#{details}")
  end
end
