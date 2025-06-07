defmodule Sdk.SendTransactionTest do
  require Logger
  use ExUnit.Case
  require IEx
  alias Sdk.Wallet
  alias TxIn
  alias TxOut
  alias Sdk.RpcClient
  @moduletag :skip

  test "use wallet and create transaction" do
    seed_wallet =
      Wallet.from_seed("4ac2c2d606a110b150ff849fef221cc71643a03517ca7fda185a8ca1d410c7d4")

    sender = Wallet.derive_private_key(seed_wallet, "m/84'/1'/0'/0/0")
    receiver = Wallet.derive_private_key(seed_wallet, "m/44'/1'/0'/0/0")

    {:ok, sender_address} = Wallet.generate_address(sender, type: :bech32, network: :testnet)
    {:ok, receiver_address} = Wallet.generate_address(receiver, type: :base58, network: :testnet)
    Logger.debug("sender_address #{inspect(sender_address)}")
    Logger.debug("receiver #{inspect(receiver_address)}")
    assert "tb1qrxjer6fnga3d7ksll524dwsxkacqssla3umzu3" == sender_address
    assert "mkjykgkDYWePhvofKMkLqq3AEwcTYDZP3s" == receiver_address

    prev_tx =
      "3ac969f19bdf2d3bb2c216cecbe3756fa2ca36f126ca2df21cb2d772f2d5e4db"
      |> Base.decode16!(case: :lower)

    change_amount = 2000
    target_amount = 1000

    prev_index = 0
    tx_in = TxIn.new(prev_tx, prev_index, Script.new([]), 0xFFFFFFFF, :segwit)

    # 21 bytes of data: If the decoded data (including the witness version) is 21 bytes long, it is a P2WPKH address (1-byte version + 20-byte key hash).
    # 33 bytes of data: If the decoded data is 33 bytes long, it is a P2WSH address (1-byte version + 32-byte script hash).
    {:ok, {:bech32, _, changed_address_decoded}} = Bech32.decode(sender_address)
    [witness_version | program_5bit] = changed_address_decoded
    # 2. Convert the 5-bit program to an 8-bit (byte) binary
    # This should produce a 20-byte binary for your P2WPKH address.
    # The `false` argument at the end disables padding, which is correct for this conversion.
    {:ok, witness_program} = Bech32.convert_bits(program_5bit, 5, 8, false)

    # 3. Construct the correct P2WPKH scriptPubKey
    change_script = Script.new([witness_version, witness_program |> :erlang.list_to_binary()])

    change_amount = trunc(change_amount)
    change_output = TxOut.new(change_amount, change_script)

    target_amount = trunc(target_amount)
    target_h160 = Base58.decode(receiver_address)
    target_script = Script.p2pkh_script(target_h160)
    target_output = TxOut.new(target_amount, target_script)

    private_key = sender.xprv.private_key |> PrivateKey.new()
    public_key = sender.xpub
    Logger.debug("receiver #{inspect(sender.xprv.private_key |> Integer.to_string(16))}")
    tx = Tx.new(2, [tx_in], [change_output, target_output], 0) |> Tx.sign(private_key, public_key)
    #    Logger.debug("Signed tx #{inspect(tx)}")
    #    Logger.debug("Private key #{inspect(private_key.secret)}")
    #    Logger.debug("Private key #{inspect(sender.xpub.public_key |> Base.encode16(case: :lower))}")
    tx_build = Tx.serialize(tx, :segwit) |> Base.encode16(case: :lower)
    rpc = RpcClient.new()
    #    Logger.debug(tx_build)

    tx_result =
      case RpcClient.send_raw_transaction(rpc, tx_build) do
        {:ok, tx} ->
          Logger.debug(tx)
          Map.get(tx, "result")

        error ->
          Logger.debug("#{inspect(error)}")
          {:error, error}
      end

    Logger.info("Transaction Result: #{inspect(tx_result)}")
  end
end
