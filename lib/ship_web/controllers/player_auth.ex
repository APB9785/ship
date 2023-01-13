defmodule ShipWeb.PlayerAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Ship.Players
  alias ShipWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in PlayerToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_ship_web_player_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the player in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_player(conn, player, params \\ %{}) do
    token = Players.generate_player_session_token(player)
    player_return_to = get_session(conn, :player_return_to)

    conn
    |> renew_session()
    |> put_session(:player_token, token)
    |> put_session(:live_socket_id, "players_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: player_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the player out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_player(conn) do
    player_token = get_session(conn, :player_token)
    player_token && Players.delete_session_token(player_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      ShipWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the player by looking into the session
  and remember me token.
  """
  def fetch_current_player(conn, _opts) do
    {player_token, conn} = ensure_player_token(conn)
    player = player_token && Players.get_player_by_session_token(player_token)
    assign(conn, :current_player, player)
  end

  defp ensure_player_token(conn) do
    if player_token = get_session(conn, :player_token) do
      {player_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if player_token = conn.cookies[@remember_me_cookie] do
        {player_token, put_session(conn, :player_token, player_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the player to not be authenticated.
  """
  def redirect_if_player_is_authenticated(conn, _opts) do
    if conn.assigns[:current_player] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the player to be authenticated.

  If you want to enforce the player email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_player(conn, _opts) do
    if conn.assigns[:current_player] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.player_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :player_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end
