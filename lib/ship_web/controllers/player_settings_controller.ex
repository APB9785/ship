defmodule ShipWeb.PlayerSettingsController do
  use ShipWeb, :controller

  alias Ship.Players
  alias ShipWeb.PlayerAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "player" => player_params} = params
    player = conn.assigns.current_player

    case Players.apply_player_email(player, password, player_params) do
      {:ok, applied_player} ->
        Players.deliver_update_email_instructions(
          applied_player,
          player.email,
          &Routes.player_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.player_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "player" => player_params} = params
    player = conn.assigns.current_player

    case Players.update_player_password(player, password, player_params) do
      {:ok, player} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:player_return_to, Routes.player_settings_path(conn, :edit))
        |> PlayerAuth.log_in_player(player)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Players.update_player_email(conn.assigns.current_player, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.player_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.player_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    player = conn.assigns.current_player

    conn
    |> assign(:email_changeset, Players.change_player_email(player))
    |> assign(:password_changeset, Players.change_player_password(player))
  end
end
