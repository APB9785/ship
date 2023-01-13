defmodule ShipWeb.PlayerSettingsControllerTest do
  use ShipWeb.ConnCase, async: true

  alias Ship.Players
  import Ship.PlayersFixtures

  setup :register_and_log_in_player

  describe "GET /players/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.player_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if player is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.player_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.player_session_path(conn, :new)
    end
  end

  describe "PUT /players/settings (change password form)" do
    test "updates the player password and resets tokens", %{conn: conn, player: player} do
      new_password_conn =
        put(conn, Routes.player_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_player_password(),
          "player" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.player_settings_path(conn, :edit)
      assert get_session(new_password_conn, :player_token) != get_session(conn, :player_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Players.get_player_by_email_and_password(player.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.player_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "player" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :player_token) == get_session(conn, :player_token)
    end
  end

  describe "PUT /players/settings (change email form)" do
    @tag :capture_log
    test "updates the player email", %{conn: conn, player: player} do
      conn =
        put(conn, Routes.player_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_player_password(),
          "player" => %{"email" => unique_player_email()}
        })

      assert redirected_to(conn) == Routes.player_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Players.get_player_by_email(player.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.player_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "player" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /players/settings/confirm_email/:token" do
    setup %{player: player} do
      email = unique_player_email()

      token =
        extract_player_token(fn url ->
          Players.deliver_update_email_instructions(%{player | email: email}, player.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the player email once", %{conn: conn, player: player, token: token, email: email} do
      conn = get(conn, Routes.player_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.player_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Players.get_player_by_email(player.email)
      assert Players.get_player_by_email(email)

      conn = get(conn, Routes.player_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.player_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, player: player} do
      conn = get(conn, Routes.player_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.player_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Players.get_player_by_email(player.email)
    end

    test "redirects if player is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.player_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.player_session_path(conn, :new)
    end
  end
end
