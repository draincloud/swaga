defmodule Transaction.PSBT.Test do
  require Logger
  use ExUnit.Case
  require IEx
  alias Sdk.Wallet
  alias Transaction.Input
  alias Transaction.Output
  alias Transaction
  alias Sdk.RpcClient
  alias Transaction.PSBT

  @tag :in_progress
  test "test psbt creation Segwit" do
    seed_wallet =
      Wallet.from_seed("4ac2c2d606a110b150ff849fef221cc71643a03517ca7fda185a8ca1d410c7d4")

    derive_path = "m/84'/1'/0'/0/0"
    sender = Wallet.derive_private_key(seed_wallet, derive_path)

    {:ok, sender_address} = Wallet.generate_address(sender, type: :bech32, network: :testnet)
    receiver_address = "tb1qlj64u6fqutr0xue85kl55fx0gt4m4urun25p7q"

    # ------------INPUT----------------
    prev_tx =
      "3ac969f19bdf2d3bb2c216cecbe3756fa2ca36f126ca2df21cb2d772f2d5e4db"
      |> Base.decode16!(case: :lower)

    change_amount = 2000
    target_amount = 1000

    prev_index = 0
    tx_in = Input.new(prev_tx, prev_index, Script.new([]), 0xFFFFFFFF, :segwit)

    # ------------CHANGE----------------
    {:ok, {:bech32, _, changed_address_decoded}} = Bech32.decode(sender_address)
    [witness_version | program_5bit] = changed_address_decoded
    {:ok, witness_program} = Bech32.convert_bits(program_5bit, 5, 8, false)
    change_script = Script.new([witness_version, witness_program |> :erlang.list_to_binary()])
    change_amount = trunc(change_amount)
    change_output = Output.new(change_amount, change_script)

    # ------------TARGET----------------
    {:ok, {:bech32, _, received_address_decoded}} = Bech32.decode(receiver_address)
    [witness_version | program_5bit] = changed_address_decoded
    {:ok, witness_program} = Bech32.convert_bits(program_5bit, 5, 8, false)
    target_amount = trunc(target_amount)
    target_script = Script.new([witness_version, witness_program |> :erlang.list_to_binary()])
    target_output = Output.new(target_amount, target_script)

    # ------------PSBT----------------
    tx =
      Transaction.new(2, [tx_in], [change_output, target_output], 0)

    psbt = Transaction.PSBT.new(tx, derive_path)
    updated_psbt = Transaction.PSBT.add_sign_info(psbt)
    Logger.info("Updated #{inspect(updated_psbt)}")
  end
end
