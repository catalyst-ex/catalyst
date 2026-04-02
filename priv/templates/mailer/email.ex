defmodule Catalyst.Mailer.Email do
  @moduledoc """
  Email template behavior
  """

  # Using Macro
  # -----------

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component
      use CatalystWeb, :verified_routes

      import Catalyst.Mailer.Layouts.DefaultLayout

      alias Catalyst.Mailer
      alias Catalyst.Mailer.Email

      @behaviour Catalyst.Mailer.Email

      @spec send(map()) :: :ok
      def send(%{} = data), do: Email.__send__(__MODULE__, data)

      @impl true
      def text_body(_assigns), do: nil

      defoverridable text_body: 1
    end
  end

  # Callbacks
  # ---------

  @doc """
  Initialize or prepare passed params
  """
  @callback init(map()) :: map()

  @doc """
  Add email metadata
  """
  @callback meta(map()) :: Swoosh.Email.t()

  @doc """
  Email html body
  """
  @callback html_body(map()) :: Phoenix.LiveView.Rendered.t()

  @doc """
  Email text body
  """
  @callback text_body(map()) :: String.t()

  # Public API
  # ----------

  defdelegate new(), to: Swoosh.Email
  defdelegate to(email, to), to: Swoosh.Email
  defdelegate from(email, from), to: Swoosh.Email
  defdelegate reply_to(email, to), to: Swoosh.Email
  defdelegate subject(email, subject), to: Swoosh.Email
  defdelegate html_body(email, body), to: Swoosh.Email
  defdelegate text_body(email, body), to: Swoosh.Email
  defdelegate put_provider_option(email, key, value), to: Swoosh.Email

  # Macro Implementation
  # --------------------

  def __send__(module, data) do
    assigns =
      data
      |> Map.put(:__changed__, nil)
      |> module.init()

    email = module.meta(assigns)
    html = module.html_body(assigns)
    text = module.text_body(assigns)

    email
    |> text_body(text)
    |> html_body(render(html))
    |> prepare()
    |> Catalyst.Mailer.deliver!()
  end

  # Helpers
  # -------

  def disable_tracking(email) do
    Swoosh.Email.put_provider_option(email, :tracked, false)
  end

  # Private Helpers
  # ---------------

  defp prepare(email) do
    email_address =
      email.to
      |> List.first()
      |> elem(1)

    Swoosh.Email.put_provider_option(email, :identifiers, %{email: email_address})
  end

  # Convert HEEx to an HTML string for Swoosh
  defp render(%Phoenix.LiveView.Rendered{} = body) do
    body
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp render(body) when is_binary(body), do: body
  defp render(nil), do: nil
end
