require Logger

defmodule MerkleTreeTest do
  use ExUnit.Case

  test "merkle parent" do
    hex_hashes =
      [
        "c117ea8ec828342f4dfb0ad6bd140e03a50720ece40169ee38bdc15d9eb64cf5",
        "c131474164b412e3406696da1ee20ab0fc9bf41c8f05fa8ceea7a08d672d7cc5",
        "f391da6ecfeed1814efae39e7fcb3838ae0b02c02ae7d0a5848a66947c0727b0",
        "3d238a92a94532b946c90e19c49351c763696cff3db400485b813aecb8a13181",
        "10092f2633be5f3ce349bf9ddbde36caa3dd10dfa0ec8106bce23acbff637dae"
      ]
      |> Enum.map(fn x -> Base.decode16!(x, case: :lower) end)

    parents =
      MerkleTree.merkle_parent_level(hex_hashes)
      |> Enum.map(fn x -> Base.encode16(x, case: :lower) end)

    assert Enum.at(parents, 0) ==
             "8b30c5ba100f6f2e5ad1e2a742e5020491240f8eb514fe97c713c31718ad7ecd"

    assert 3 == length(parents)
  end

  test "merkle root" do
    hex_hashes =
      [
        "c117ea8ec828342f4dfb0ad6bd140e03a50720ece40169ee38bdc15d9eb64cf5",
        "c131474164b412e3406696da1ee20ab0fc9bf41c8f05fa8ceea7a08d672d7cc5",
        "f391da6ecfeed1814efae39e7fcb3838ae0b02c02ae7d0a5848a66947c0727b0",
        "3d238a92a94532b946c90e19c49351c763696cff3db400485b813aecb8a13181",
        "10092f2633be5f3ce349bf9ddbde36caa3dd10dfa0ec8106bce23acbff637dae",
        "7d37b3d54fa6a64869084bfd2e831309118b9e833610e6228adacdbd1b4ba161",
        "8118a77e542892fe15ae3fc771a4abfd2f5d5d5997544c3487ac36b5c85170fc",
        "dff6879848c2c9b62fe652720b8df5272093acfaa45a43cdb3696fe2466a3877",
        "b825c0745f46ac58f7d3759e6dc535a1fec7820377f24d4c2c6ad2cc55c0cb59",
        "95513952a04bd8992721e9b7e2937f1c04ba31e0469fbe615a78197f68f52b7c",
        "2e6d722e5e4dbdf2447ddecc9f7dabb8e299bae921c99ad5b0184cd9eb8e5908",
        "b13a750047bc0bdceb2473e5fe488c2596d7a7124b4e716fdd29b046ef99bbf0"
      ]
      |> Enum.map(fn x -> Base.decode16!(x, case: :lower) end)

    root = MerkleTree.merkle_root(hex_hashes) |> Base.encode16(case: :lower)
    assert "acbcab8bcc1af95d8d563b77d24c3d19b18f1486383d75a5085c4e86c86beed6" == root
  end

  test "new" do
    tree = MerkleTree.new(9)
    assert length(Enum.at(tree.nodes, 0)) == 1
    assert length(Enum.at(tree.nodes, 1)) == 2
    assert length(Enum.at(tree.nodes, 2)) == 3
    assert length(Enum.at(tree.nodes, 3)) == 5
    assert length(Enum.at(tree.nodes, 4)) == 9
  end
end
