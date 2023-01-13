defmodule ShipWeb.PlayerConfirmationController do
  use ShipWeb, :controller

  alias Ship.Players

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"player" => %{"email" => email}}) do
    if player = Players.get_player_by_email(email) do
      Players.deliver_player_confirmation_instructions(
        player,
        &Routes.player_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the player after confirmation to avoid a
  # leaked token giving the player access to the account.
  def update(conn, %{"token" => token}) do
    case Players.confirm_player(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Player confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current player and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the player themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_player: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Player confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
