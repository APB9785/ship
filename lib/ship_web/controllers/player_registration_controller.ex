defmodule ShipWeb.PlayerRegistrationController do
  use ShipWeb, :controller

  alias Ship.Players
  alias Ship.Players.Player
  alias ShipWeb.PlayerAuth

  def new(conn, _params) do
    changeset = Players.change_player_registration(%Player{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"player" => player_params}) do
    case Players.register_player(player_params) do
      {:ok, player} ->
        {:ok, _} =
          Players.deliver_player_confirmation_instructions(
            player,
            &Routes.player_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Player created successfully.")
        |> PlayerAuth.log_in_player(player)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
