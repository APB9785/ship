defmodule Ship.Manager do
  @moduledoc """
  ECSx manager.
  """
  use ECSx.Manager, tick_rate: 20

  setup do
    for _player_count <- 1..44 do
      # First generate a unique ID to represent the new entity
      entity = Ecto.UUID.generate()

      # Then use that ID to create the components which make up a ship
      Ship.Components.ArmorRating.add(entity, 0)
      Ship.Components.AttackDamage.add(entity, 5)
      Ship.Components.AttackRange.add(entity, 10)
      Ship.Components.AttackSpeed.add(entity, 1.05)
      Ship.Components.HullPoints.add(entity, 50)
      Ship.Components.SeekingTarget.add(entity)
      Ship.Components.XPosition.add(entity, Enum.random(1..100))
      Ship.Components.XVelocity.add(entity, 0)
      Ship.Components.YPosition.add(entity, Enum.random(1..100))
      Ship.Components.YVelocity.add(entity, 0)
    end
  end

  # Declare all valid Component types
  def components do
    [
      Ship.Components.PlayerSpawned,
      Ship.Components.DestroyedAt,
      Ship.Components.AttackCooldown,
      Ship.Components.AttackTarget,
      Ship.Components.SeekingTarget,
      Ship.Components.AttackSpeed,
      Ship.Components.YVelocity,
      Ship.Components.XVelocity,
      Ship.Components.YPosition,
      Ship.Components.XPosition,
      Ship.Components.AttackRange,
      Ship.Components.AttackDamage,
      Ship.Components.ArmorRating,
      Ship.Components.HullPoints
    ]
  end

  # Declare all Systems to run
  def systems do
    [
      Ship.Systems.ClientEventHandler,
      Ship.Systems.Destruction,
      Ship.Systems.CooldownExpiration,
      Ship.Systems.Attacking,
      Ship.Systems.Targeting,
      Ship.Systems.Driver
    ]
  end
end
