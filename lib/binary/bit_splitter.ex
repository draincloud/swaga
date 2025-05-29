defmodule Binary.BitSplitter do
  def split(bin, chunk_size) when is_bitstring(bin) and bit_size(bin) >= chunk_size do
    case rem(bit_size(bin), chunk_size) do
      0 -> {:ok, do_split(bin, chunk_size, [])}
      _ -> {:error, "Incorrect chunk_size #{chunk_size} for bin length #{bit_size(bin)}"}
    end
  end

  defp do_split(<<>>, _, chunks) when is_list(chunks) do
    chunks
  end

  defp do_split(bin, chunk_size, chunks) when is_list(chunks) do
    <<chunk::bitstring-size(chunk_size), rest::bitstring>> = bin
    do_split(rest, chunk_size, chunks ++ [chunk])
  end
end
