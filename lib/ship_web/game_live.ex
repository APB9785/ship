defmodule ShipWeb.GameLive do
  use ShipWeb, :live_view

  alias Ship.Components.XPosition
  alias Ship.Components.YPosition

  def mount(_params, %{"player_token" => token} = _session, socket) do
    # This context function was generated by phx.gen.auth
    player = Ship.Players.get_player_by_session_token(token)

    # We must spawn the ship before processing any other input
    ECSx.ClientEvents.add(to_string(player.id), :spawn_ship)

    # We want to keep up-to-date on our ship's location
    :timer.send_interval(50, :refresh_current_location)

    # Keeping a set of currently held keys will allow us to prevent duplicate keydown events
    keys = MapSet.new()

    {:ok,
     assign(socket,
       player: %{player | id: to_string(player.id)},
       keys: keys,
       current_location: nil
     )}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    if MapSet.member?(socket.assigns.keys, key) do
      # Already holding this key - do nothing
      {:noreply, socket}
    else
      ECSx.ClientEvents.add(socket.assigns.player.id, keydown(key))
      {:noreply, assign(socket, keys: MapSet.put(socket.assigns.keys, key))}
    end
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    # We don't have to worry about duplicate keyup events
    ECSx.ClientEvents.add(socket.assigns.player.id, keyup(key))
    {:noreply, assign(socket, keys: MapSet.delete(socket.assigns.keys, key))}
  end

  defp keydown(key) when key in ~w(w W ArrowUp), do: {:move, :north}
  defp keydown(key) when key in ~w(a A ArrowLeft), do: {:move, :west}
  defp keydown(key) when key in ~w(s S ArrowDown), do: {:move, :south}
  defp keydown(key) when key in ~w(d D ArrowRight), do: {:move, :east}

  defp keyup(key) when key in ~w(w W ArrowUp), do: {:stop_move, :north}
  defp keyup(key) when key in ~w(a A ArrowLeft), do: {:stop_move, :west}
  defp keyup(key) when key in ~w(s S ArrowDown), do: {:stop_move, :south}
  defp keyup(key) when key in ~w(d D ArrowRight), do: {:stop_move, :east}

  def handle_info(:refresh_current_location, socket) do
    player_entity = socket.assigns.player.id
    x = XPosition.get_one(player_entity)
    y = YPosition.get_one(player_entity)

    {:noreply, assign(socket, current_location: {x, y})}
  end

  def render(assigns) do
    ~H"""
    <div id="game" phx-window-keydown="keydown" phx-window-keyup="keyup">
      <p>Player ID: <%= @player.id %></p>
      <p>Player Coords: <%= inspect(@current_location) %></p>
    </div>
    """
  end
end
