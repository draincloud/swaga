defmodule ChainCode do
  def from_hmac(hmac) when is_binary(hmac) do
    <<_::binary-size(32), chain_code::binary-size(32)>> = hmac
    chain_code
  end
end
