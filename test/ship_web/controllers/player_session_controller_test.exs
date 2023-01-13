defmodule ShipWeb.PlayerSessionControllerTest do
  use ShipWeb.ConnCase, async: true

  import Ship.PlayersFixtures

  setup do
    %{player: player_fixture()}
  end

  describe "GET /players/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.player_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"
    end

    test "redirects if already logged in", %{conn: conn, player: player} do
      conn = conn |> log_in_player(player) |> get(Routes.player_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /players/log_in" do
    test "logs the player in", %{conn: conn, player: player} do
      conn =
        post(conn, Routes.player_session_path(conn, :create), %{
          "player" => %{"email" => player.email, "password" => valid_player_password()}
        })

      assert get_session(conn, :player_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ player.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the player in with remember me", %{conn: conn, player: player} do
      conn =
        post(conn, Routes.player_session_path(conn, :create), %{
          "player" => %{
            "email" => player.email,
            "password" => valid_player_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_ship_web_player_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the player in with return to", %{conn: conn, player: player} do
      conn =
        conn
        |> init_test_session(player_return_to: "/foo/bar")
        |> post(Routes.player_session_path(conn, :create), %{
          "player" => %{
            "email" => player.email,
            "password" => valid_player_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, player: player} do
      conn =
        post(conn, Routes.player_session_path(conn, :create), %{
          "player" => %{"email" => player.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /players/log_out" do
    test "logs the player out", %{conn: conn, player: player} do
      conn = conn |> log_in_player(player) |> delete(Routes.player_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :player_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the player is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.player_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :player_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
