# defmodule Tx.InputWitness do
#  alias Signature
#  alias BIP32.Xpub
#
#  @moduledoc """
#  Represents the witness stack for a single transaction input.
#  """
#  defstruct [:signature, :public_key]
#  @enforce_keys [:signature, :public_key]
#  @type t :: %__MODULE__{signature: Signature.t(), public_key: Xpub}
#
#  def new(signature, pubkey) when is_struct(signature, Signature) and is_struct(pubkey, Xpub) do
#    %__MODULE__{signature: signature, public_key: pubkey}
#  end
#
#  @doc """
#  Serialized P2WPKH [[<signature_bin>, <compressed_pubkey_bin>]]
#  """
#  def serialize(%__MODULE__{signature: signature, public_key: pubkey}) do
#    Signature.der() <> pubkey.public_key
#  end
# end
