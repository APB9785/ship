defmodule Ship.Components.XPosition do
  @moduledoc """
  Documentation for XPosition components.
  """
  use ECSx.Component,
    value: :integer,
    unique: true
end