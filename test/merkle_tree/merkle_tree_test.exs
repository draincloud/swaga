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

  @tag :in_progress
  test "populate the tree" do
    hex_hashes =
      [
        "9745f7173ef14ee4155722d1cbf13304339fd00d900b759c6f9d58579b5765fb",
        "5573c8ede34936c29cdfdfe743f7f5fdfbd4f54ba0705259e62f39917065cb9b",
        "82a02ecbb6623b4274dfcab82b336dc017a27136e08521091e443e62582e8f05",
        "507ccae5ed9b340363a0e6d765af148be9cb1c8766ccc922f83e4ae681658308",
        "a7a4aec28e7162e1e9ef33dfa30f0bc0526e6cf4b11a576f6c5de58593898330",
        "bb6267664bd833fd9fc82582853ab144fece26b7a8a5bf328f8a059445b59add",
        "ea6d7ac1ee77fbacee58fc717b990c4fcccf1b19af43103c090f601677fd8836",
        "457743861de496c429912558a106b810b0507975a49773228aa788df40730d41",
        "7688029288efc9e9a0011c960a6ed9e5466581abf3e3a6c26ee317461add619a",
        "b1ae7f15836cb2286cdd4e2c37bf9bb7da0a2846d06867a429f654b2e7f383c9",
        "9b74f89fa3f93e71ff2c241f32945d877281a6a50a6bf94adac002980aafe5ab",
        "b3a92b5b255019bdaf754875633c2de9fec2ab03e6b8ce669d07cb5b18804638",
        "b5c0b915312b9bdaedd2b86aa2d0f8feffc73a2d37668fd9010179261e25e263",
        "c9d52c5cb1e557b92c84c52e7c4bfbce859408bedffc8a5560fd6e35e10b8800",
        "c555bc5fc3bc096df0a0c9532f07640bfb76bfe4fc1ace214b8b228a1297a4c2",
        "f9dbfafc3af3400954975da24eb325e326960a25b87fffe23eef3e7ed2fb610e"
      ]
      |> Enum.map(fn h -> Base.decode16!(h, case: :lower) end)

    tree = MerkleTree.new(length(hex_hashes))
    root = MerkleTree.populate_tree(tree, List.duplicate(1, 31), hex_hashes)

    assert root |> Base.encode16(case: :lower) ==
             "597c4bafe3832b17cbbabe56f878f4fc2ad0f6a402cee7fa851a9cb205f87ed1"
  end
end
