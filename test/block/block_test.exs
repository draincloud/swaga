defmodule BlockTest do
  use ExUnit.Case

  test "parse" do
    block_raw =
      Base.decode16!(
        "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert block.version == 0x20000002

    want =
      Base.decode16!("000000000000000000fd0c220a0a8c3bc5a7b487e8c8de0dfa2373b12894c38e",
        case: :lower
      )

    assert block.prev_block == want

    want =
      Base.decode16!("be258bfd38db61f957315c3f9e9c5e15216857398d50402d5089a8e0fc50075b",
        case: :lower
      )

    assert block.merkle_root == want
    assert block.timestamp == 0x59A7771E
    assert block.bits == Base.decode16!("e93c0118", case: :lower)
    assert block.nonce == Base.decode16!("a4ffd71d", case: :lower)
  end

  test "serialized" do
    block_raw =
      Base.decode16!(
        "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert Block.serialize(block) == block_raw
  end

  @tag :in_progress
  test "hash" do
    block_raw =
      Base.decode16!(
        "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
        case: :lower
      )

    block = Block.parse(block_raw)

    assert Block.hash(block) ==
             Base.decode16!("0000000000000000007e9e4c586439b0cdbe13b1370bdd9435d76a644d047523",
               case: :lower
             )
  end
end
