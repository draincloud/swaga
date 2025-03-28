defmodule Secp256Field do
  @enforce_keys [:num, :prime]
  defstruct [:num, :prime]

  def new(num) do
    p = 2 ** 256 - 2 ** 32 - 977
    FieldElement.new(num, p)
  end
end
