defmodule BIP32.DerivationPath do
  defstruct [:numbers]
  # Parse to list of ChildNumber
  def parse(path), do: ""
  # Empty path for master key
  def master(), do: ""
  # Append child number
  def child(path, child_number), do: ""
  # Concat paths
  def extend(path, numbers), do: ""
end
