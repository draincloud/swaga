require Logger

defmodule MerkleTree do
  # 1. Hash all the items of the ordered list with the provided hash function.
  # 2. If there is exactly 1 hash, we are done.
  # 3. Otherwise, if there is an odd number of hashes, we duplicate the last hash in the
  # list and add it to the end so that we have an even number of hashes.
  # 4. We pair the hashes in order and hash the concatenation to get the parent level,
  # which should have half the number of hashes.
  # 5. Go to #2

  @enforce_keys [:total, :max_depth, :nodes, :current_depth, :current_index]
  defstruct [:total, :max_depth, :nodes, :current_depth, :current_index]

  def new(total_leaves) when is_integer(total_leaves) do
    max_depth =
      total_leaves
      |> :math.log2()
      |> Float.ceil()
      |> round()

    Logger.debug("max depth #{inspect(max_depth)}")

    nodes =
      0..max_depth
      |> Enum.with_index()
      |> Enum.reduce([], fn {i, x}, acc ->
        # the number of items at this depth
        num_items = (total_leaves / :math.pow(2, max_depth - i)) |> Float.ceil() |> round
        acc ++ [List.duplicate(:leave, num_items)]
      end)

    nodes

    %MerkleTree{
      total: total_leaves,
      max_depth: max_depth,
      nodes: nodes,
      current_depth: 0,
      current_index: 0
    }
  end

  def up(%MerkleTree{current_depth: depth, current_index: index} = merkle_tree)
      when depth > 0 and index > 0 do
    %MerkleTree{merkle_tree | current_depth: depth - 1, current_index: div(index, 2)}
  end

  def left(%MerkleTree{current_depth: depth, current_index: index} = merkle_tree)
      when depth > 0 and index > 0 do
    %MerkleTree{merkle_tree | current_depth: depth + 1, current_index: index * 2}
  end

  def right(%MerkleTree{current_depth: depth, current_index: index} = merkle_tree)
      when depth > 0 and index > 0 do
    %MerkleTree{merkle_tree | current_depth: depth + 1, current_index: index * 2 + 1}
  end

  def root(%MerkleTree{nodes: nodes}) do
    nodes |> Enum.at(0) |> Enum.at(0)
  end

  def set_current_node(
        %MerkleTree{nodes: nodes, current_depth: current_depth, current_index: current_index} =
          merkle_tree,
        node
      ) do
    new_nodes =
      nodes |> List.updated_at(current_depth, fn row -> List.replace_at(current_index) end)

    %MerkleTree{merkle_tree | nodes: new_nodes}
  end

  def get_current_node(%MerkleTree{
        nodes: nodes,
        current_depth: current_depth,
        current_index: current_index
      }) do
    nodes |> Enum.at(current_depth) |> Enum.at(current_index)
  end

  def get_left_node(%MerkleTree{
        nodes: nodes,
        current_depth: current_depth,
        current_index: current_index
      }) do
    nodes |> Enum.at(current_depth + 1) |> Enum.at(current_index * 2)
  end

  def get_right_node(%MerkleTree{
        nodes: nodes,
        current_depth: current_depth,
        current_index: current_index
      }) do
    nodes |> Enum.at(current_depth + 1) |> Enum.at(current_index * 2 + 1)
  end

  def is_leaf(%MerkleTree{
        current_depth: current_depth,
        max_depth: max
      }) do
    current_depth == max
  end

  def right_exists(%MerkleTree{
        nodes: nodes,
        current_depth: current_depth,
        current_index: current_index
      }) do
    nodes |> Enum.at(current_depth + 1) |> length > current_index * 2 + 1
  end

  def populate_tree(%MerkleTree{}, flag_bits, hashes) do
  end

  def merkle_parent(hash_l, hash_r) do
    hash_int = CryptoUtils.double_hash256(hash_l <> hash_r)
    ## if we do :binary.encode_unsigned it strips the leading zeros
    <<hash_int::unsigned-big-integer-size(256)>>
  end

  # Merkle Parent level is calculated parents of each pair
  # If we have odd number of pairs, we duplicate the last item [A,B,C] -> [A,B,C,C]
  def merkle_parent_level(hashes) when is_list(hashes) and rem(length(hashes), 2) == 0 do
    {nil, result} =
      Enum.reduce(hashes, {nil, []}, fn x, {prev, parents} ->
        if prev != nil do
          parent = merkle_parent(prev, x)
          Logger.debug("parent byte size #{inspect(byte_size(parent))}")
          {nil, parents ++ [parent]}
        else
          {x, parents}
        end
      end)

    result
  end

  def merkle_parent_level(hashes) when is_list(hashes) and rem(length(hashes), 2) != 0 do
    last = List.last(hashes)
    Logger.debug("last #{inspect(last)}")
    merkle_parent_level(hashes ++ [last])
  end

  def merkle_root(hashes) when length(hashes) == 1 do
    hashes |> Enum.at(0)
  end

  def merkle_root(hashes) do
    merkle_parent_level(hashes) |> merkle_root()
  end
end
