require Logger

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

  test "parse the version of block" do
    import Bitwise

    block =
      Block.parse(
        Base.decode16!(
          "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
          case: :lower
        )
      )

    assert block.version >>> 29 == 001
  end

  test "bip09" do
    block_raw =
      Base.decode16!(
        "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert Block.bip9(block)

    block_raw =
      Base.decode16!(
        "0400000039fa821848781f027a2e6dfabbf6bda920d9ae61b63400030000000000000000ecae536a304042e3154be0e3e9a8220e5568c3433a9ab49ac4cbb74f8df8e8b0cc2acf569fb9061806652c27",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert false == Block.bip9(block)
  end

  test "bip91" do
    block_raw =
      Base.decode16!(
        "1200002028856ec5bca29cf76980d368b0a163a0bb81fc192951270100000000000000003288f32a2831833c31a25401c52093eb545d28157e200a64b21b3ae8f21c507401877b5935470118144dbfd1",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert Block.bip91(block)

    block_raw =
      Base.decode16!(
        "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert false == Block.bip91(block)
  end

  test "bip141" do
    block_raw =
      Base.decode16!(
        "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert Block.bip141(block)

    block_raw =
      Base.decode16!(
        "0000002066f09203c1cf5ef1531f24ed21b1915ae9abeb691f0d2e0100000000000000003de0976428ce56125351bae62c5b8b8c79d8297c702ea05d60feabb4ed188b59c36fa759e93c0118b74b2618",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert false == Block.bip141(block)
  end

  test "correctly calculated hash" do
    block_id =
      CryptoUtils.double_hash256(
        Base.decode16!(
          "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
          case: :lower
        )
      )
      |> :binary.encode_unsigned(:big)
      |> Helpers.reverse_binary()

    assert Base.encode16(block_id, case: :lower) ==
             "0000000000000000007e9e4c586439b0cdbe13b1370bdd9435d76a644d047523"
  end

  test "target and difficulty" do
    block_raw =
      Base.decode16!(
        "020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert Block.bits_to_target(block.bits) == 0x13CE9000000000000000000000000000000000000000000
    assert trunc(Block.difficulty(block)) == 888_171_856_257
  end

  test "check pow" do
    block_raw =
      Base.decode16!(
        "04000000fbedbbf0cfdaf278c094f187f2eb987c86a199da22bbb20400000000000000007b7697b29129648fa08b4bcd13c9d5e60abb973a1efac9c8d573c71c807c56c3d6213557faa80518c3737ec1",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert Block.check_pow(block)

    block_raw =
      Base.decode16!(
        "04000000fbedbbf0cfdaf278c094f187f2eb987c86a199da22bbb20400000000000000007b7697b29129648fa08b4bcd13c9d5e60abb973a1efac9c8d573c71c807c56c3d6213557faa80518c3737ec0",
        case: :lower
      )

    block = Block.parse(block_raw)
    assert not Block.check_pow(block)
  end

  test "calculate new bits" do
    prev_bits = Base.decode16!("54d80118", case: :lower)
    time_differential = 302_400
    want = Base.decode16!("00157617", case: :lower)
    assert want == Block.calculate_new_bits(prev_bits, time_differential)
  end

  test "merkle root" do
    hashes_hex =
      [
        "f54cb69e5dc1bd38ee6901e4ec2007a5030e14bdd60afb4d2f3428c88eea17c1",
        "c57c2d678da0a7ee8cfa058f1cf49bfcb00ae21eda966640e312b464414731c1",
        "b027077c94668a84a5d0e72ac0020bae3838cb7f9ee3fa4e81d1eecf6eda91f3",
        "8131a1b8ec3a815b4800b43dff6c6963c75193c4190ec946b93245a9928a233d",
        "ae7d63ffcb3ae2bc0681eca0df10dda3ca36dedb9dbf49e33c5fbe33262f0910",
        "61a14b1bbdcdda8a22e61036839e8b110913832efd4b086948a6a64fd5b3377d",
        "fc7051c8b536ac87344c5497595d5d2ffdaba471c73fae15fe9228547ea71881",
        "77386a46e26f69b3cd435aa4faac932027f58d0b7252e62fb6c9c2489887f6df",
        "59cbc055ccd26a2c4c4df2770382c7fea135c56d9e75d3f758ac465f74c025b8",
        "7c2bf5687f19785a61be9f46e031ba041c7f93e2b7e9212799d84ba052395195",
        "08598eebd94c18b0d59ac921e9ba99e2b8ab7d9fccde7d44f2bd4d5e2e726d2e",
        "f0bb99ef46b029dd6f714e4b12a7d796258c48fee57324ebdc0bbc4700753ab1"
      ]
      |> Enum.map(fn x -> Base.decode16!(x, case: :lower) end)

    stream =
      "00000020fcb19f7895db08cadc9573e7915e3919fb76d59868a51d995201000000000000acbcab8bcc1af95d8d563b77d24c3d19b18f1486383d75a5085c4e86c86beed691cfa85916ca061a00000000"
      |> Base.decode16!(case: :lower)

    block = Block.parse(stream)
    block = %Block{block | tx_hashes: hashes_hex}
    assert Block.validate_merkle_root(block)
  end
end
