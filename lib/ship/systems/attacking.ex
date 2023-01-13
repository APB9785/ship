defmodule Ship.Systems.Attacking do
  @moduledoc false
  use ECSx.System

  alias Ship.Components.ArmorRating
  alias Ship.Components.AttackCooldown
  alias Ship.Components.AttackDamage
  alias Ship.Components.AttackRange
  alias Ship.Components.AttackSpeed
  alias Ship.Components.AttackTarget
  alias Ship.Components.HullPoints
  alias Ship.Components.SeekingTarget
  alias Ship.SystemUtils

  def run do
    attack_targets = AttackTarget.get_all()

    Enum.each(attack_targets, &attack_if_ready/1)
  end

  defp attack_if_ready({self, target}) do
    cond do
      SystemUtils.distance_between(self, target) > AttackRange.get_one(self) ->
        # If the target ever leaves our attack range, we want to remove the AttackTarget
        # and begin searching for a new one.
        AttackTarget.remove(self)
        SeekingTarget.add(self)

      AttackCooldown.exists?(self) ->
        # We're still within range, but waiting on the cooldown
        :noop

      :otherwise ->
        deal_damage(self, target)
        add_cooldown(self)
    end
  end

  defp deal_damage(self, target) do
    attack_damage = AttackDamage.get_one(self)
    # Assuming one armor rating always equals one damage
    reduction_from_armor = ArmorRating.get_one(target)
    final_damage_amount = attack_damage - reduction_from_armor

    target_current_hp = HullPoints.get_one(target)
    target_new_hp = target_current_hp - final_damage_amount

    HullPoints.add(target, target_new_hp)
  end

  defp add_cooldown(self) do
    now = DateTime.utc_now()
    ms_between_attacks = calculate_cooldown_time(self)
    cooldown_until = DateTime.add(now, ms_between_attacks, :millisecond)

    AttackCooldown.add(self, cooldown_until)
  end

  # We're going to model AttackSpeed with a float representing attacks per second.
  # The goal here is to convert that into milliseconds per attack.
  defp calculate_cooldown_time(self) do
    attacks_per_second = AttackSpeed.get_one(self)
    seconds_per_attack = 1 / attacks_per_second

    ceil(seconds_per_attack * 1000)
  end
end
