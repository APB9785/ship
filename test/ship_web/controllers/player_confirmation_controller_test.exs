defmodule ShipWeb.PlayerConfirmationControllerTest do
  use ShipWeb.ConnCase, async: true

  alias Ship.Players
  alias Ship.Repo
  import Ship.PlayersFixtures

  setup do
    %{player: player_fixture()}
  end

  describe "GET /players/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.player_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /players/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, player: player} do
      conn =
        post(conn, Routes.player_confirmation_path(conn, :create), %{
          "player" => %{"email" => player.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Players.PlayerToken, player_id: player.id).context == "confirm"
    end

    test "does not send confirmation token if Player is confirmed", %{conn: conn, player: player} do
      Repo.update!(Players.Player.confirm_changeset(player))

      conn =
        post(conn, Routes.player_confirmation_path(conn, :create), %{
          "player" => %{"email" => player.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Players.PlayerToken, player_id: player.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.player_confirmation_path(conn, :create), %{
          "player" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Players.PlayerToken) == []
    end
  end

  describe "GET /players/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.player_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.player_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /players/confirm/:token" do
    test "confirms the given token once", %{conn: conn, player: player} do
      token =
        extract_player_token(fn url ->
          Players.deliver_player_confirmation_instructions(player, url)
        end)

      conn = post(conn, Routes.player_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Player confirmed successfully"
      assert Players.get_player!(player.id).confirmed_at
      refute get_session(conn, :player_token)
      assert Repo.all(Players.PlayerToken) == []

      # When not logged in
      conn = post(conn, Routes.player_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Player confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_player(player)
        |> post(Routes.player_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, player: player} do
      conn = post(conn, Routes.player_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Player confirmation link is invalid or it has expired"
      refute Players.get_player!(player.id).confirmed_at
    end
  end
end
