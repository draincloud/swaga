defmodule BIP32.ChildNumber do
  defstruct [:type, :index]
  # Convert int to normal/hardened
  def from_index(index), do: ""
  # Convert to int
  def to_index(index), do: ""
  def increment(child_number), do: ""
end
