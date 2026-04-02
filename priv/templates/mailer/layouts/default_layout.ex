defmodule Catalyst.Mailer.Layouts.DefaultLayout do
  @moduledoc """
  Provides a reusable HTML email layout for Catalyst notifications.
  """

  use Phoenix.Component
  use CatalystWeb, :verified_routes

  slot :inner_block, required: true

  def layout(assigns) do
    assigns =
      assigns
      |> assign(:logo_url, "catalyst-logo-email.png")
      |> assign(:support_email, [])
      |> assign(:social_links, [])
      |> assign(:social_icons, %{
        instagram: "social-instagram.png",
        tiktok: "social-tiktok.png",
        x: "social-x.png"
      })

    ~H"""
    <!DOCTYPE html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="x-apple-disable-message-reformatting" />
      </head>
      <body style="margin:0;padding:0;background-color:#fff;font-family:'Helvetica Neue',Arial,sans-serif;-webkit-text-size-adjust:100%;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#fff;">
          <tr>
            <td align="center" style="padding:32px 16px;">
              <table
                role="presentation"
                width="100%"
                cellspacing="0"
                cellpadding="0"
                border="0"
                style="max-width:560px;background-color:#ffffff;border-radius:28px;overflow:hidden;"
              >
                <tr>
                  <td style="padding:10px 24px 0;background-color:#f4f2ff;text-align:center;">
                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                      <tr>
                        <td align="center">
                          <img
                            src={@logo_url}
                            width="105"
                            height="28"
                            alt="Catalyst logo"
                            style="display:block;margin:0 auto 12px;border:0;height:auto;max-width:105px;"
                          />
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>

                {render_slot(@inner_block)}

                <tr>
                  <td style="padding:12px 24px 0px;background-color:#f4f2ff;">
                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:0 auto;">
                      <tr>
                        <td align="center" style="padding:12px 2px;">
                          <a href={@social_links.instagram} target="_blank" rel="noopener" style="display:inline-block;">
                            <img
                              src={@social_icons.instagram}
                              width="32"
                              height="32"
                              alt="Instagram"
                              style="display:block;border:0;height:auto;"
                            />
                          </a>
                        </td>
                        <td align="center" style="padding:12px 2px;">
                          <a href={@social_links.tiktok} target="_blank" rel="noopener" style="display:inline-block;">
                            <img
                              src={@social_icons.tiktok}
                              width="32"
                              height="32"
                              alt="TikTok"
                              style="display:block;border:0;height:auto;"
                            />
                          </a>
                        </td>
                        <td align="center" style="padding:12px 2px;">
                          <a href={@social_links.x} target="_blank" rel="noopener" style="display:inline-block;">
                            <img
                              src={@social_icons.x}
                              width="32"
                              height="32"
                              alt="X"
                              style="display:block;border:0;height:auto;"
                            />
                          </a>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td style="padding:0 24px 30px;background-color:#f4f2ff;text-align:center;">
                    <p style="margin:0 0 0;font-size:10px;line-height:16px;color:#a4a7ae;">
                      <a href={"mailto:#{@support_email}"} style="color:#a4a7ae;text-decoration:none;">
                        {@support_email}
                      </a>
                    </p>
                    <p style="margin:0;font-size:10px;line-height:16px;color:#a4a7ae;">
                      © {Date.utc_today().year} Catalyst. All rights reserved.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end
end
