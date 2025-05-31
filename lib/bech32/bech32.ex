defmodule Bech32 do
  alias Binary.BitSplitter
  @alphabet "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
  @doc """
  The overall structure of a Bech32 string is: `[hrp]1[data][checksum]`
  """
  def encode(input_data) when is_binary(input_data) do
    input_data =
      case rem(bit_size(input_data), 5) do
        0 ->
          input_data

        _ ->
          nil
      end

    {:ok, chunks} = BitSplitter.do_split(input_data, 5)
  end
end
