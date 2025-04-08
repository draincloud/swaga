defmodule Secp256Field do
  @enforce_keys [:num, :prime]
  defstruct [:num, :prime]

  @p 2 ** 256 - 2 ** 32 - 977
  def p() do
    @p
  end

  def new(num) do
    FieldElement.new(num, @p)
  end

  def sqrt(f_element) do
    FieldElement.pow(f_element, rem(@p + 1, 4))
  end
end
