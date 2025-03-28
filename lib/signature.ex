defmodule Signature do
  @enforce_keys [:r, :s]
  defstruct [:r, :s]

  def new(r, s) do
    %Signature{r: r, s: s}
  end
end
