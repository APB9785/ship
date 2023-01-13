defmodule Ship.Systems.ClientEventHandler do
  @moduledoc false
  use ECSx.System

  alias Ship.Components.ArmorRating
  alias Ship.Components.AttackDamage
  alias Ship.Components.AttackRange
  alias Ship.Components.AttackSpeed
  alias Ship.Components.HullPoints
  alias Ship.Components.SeekingTarget
  alias Ship.Components.XPosition
  alias Ship.Components.XVelocity
  alias Ship.Components.YPosition
  alias Ship.Components.YVelocity

  def run do
    client_events = ECSx.ClientEvents.get_and_clear()

    Enum.each(client_events, &process_one/1)
  end

  defp process_one({player, :spawn_ship}) do
    ArmorRating.add(player, 2)
    AttackDamage.add(player, 6)
    AttackRange.add(player, 15)
    AttackSpeed.add(player, 1.2)
    HullPoints.add(player, 75)
    SeekingTarget.add(player)
    XPosition.add(player, Enum.random(1..100))
    YPosition.add(player, Enum.random(1..100))
  end

  defp process_one({player, {:move, :north}}), do: YVelocity.add(player, 1)
  defp process_one({player, {:move, :south}}), do: YVelocity.add(player, -1)
  defp process_one({player, {:move, :east}}), do: XVelocity.add(player, 1)
  defp process_one({player, {:move, :west}}), do: XVelocity.add(player, -1)

  defp process_one({player, {:stop_move, direction}}) when direction in [:north, :south],
    do: YVelocity.remove(player)

  defp process_one({player, {:stop_move, direction}}) when direction in [:east, :west],
    do: XVelocity.remove(player)
end
