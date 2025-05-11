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

    nodes =
      0..max_depth
      |> Enum.with_index()
      |> Enum.reduce([], fn {i, _}, acc ->
        # the number of items at this depth
        num_items = (total_leaves / :math.pow(2, max_depth - i)) |> Float.ceil() |> round
        acc ++ [List.duplicate(:none, num_items)]
      end)

    %MerkleTree{
      total: total_leaves,
      max_depth: max_depth,
      nodes: nodes,
      current_depth: 0,
      current_index: 0
    }
  end

  def up(%MerkleTree{current_depth: 0} = tree), do: tree

  def up(%MerkleTree{current_depth: depth, current_index: index} = merkle_tree)
      when depth > 0 and index >= 0 do
    %MerkleTree{merkle_tree | current_depth: depth - 1, current_index: div(index, 2)}
  end

  def left(%MerkleTree{current_depth: depth, current_index: index} = merkle_tree)
      when depth >= 0 and index >= 0 do
    %MerkleTree{merkle_tree | current_depth: depth + 1, current_index: index * 2}
  end

  def right(%MerkleTree{current_depth: depth, current_index: index} = merkle_tree)
      when depth >= 0 and index >= 0 do
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
      nodes
      |> List.update_at(current_depth, fn row -> List.replace_at(row, current_index, node) end)

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

  @doc """
  The point of populating this Merkle tree is to calculate the root. Each loop iteration processes one node until the root is calculated
  hashes = For leaf nodes, we are always given the hash

  """
  def populate_tree(%MerkleTree{} = tree, flag_bits, hashes) do
    # We populate until we have the root
    root = root(tree)
    #
    case root do
      :none ->
        {updated_tree, updated_flag_bits, updated_hashes} =
          parse_tree(tree, flag_bits, hashes)

        populate_tree(updated_tree, updated_flag_bits, updated_hashes)

      actual_root when is_binary(actual_root) ->
        # sanity‐check
        if flag_bits == [] and hashes == [] do
          actual_root
        else
          raise "didn't consume everything"
        end
    end
  end

  @doc """
  flag_bits guide where you need to descend vs. skip.
  hashes provide either leaf values (at the bottom) or pre-computed subtree hashes (where you skip)
  1 = “there’s something interesting in some leaf below → open this node.”

  0 = “no interesting leaves in here → here’s the one hash that covers it all, skip its children.”
  """
  def parse_tree(tree, flag_bits, hashes) do
    if is_leaf(tree) do
      # Get the next bit from flag_bits
      {_, rest_flags} = List.pop_at(flag_bits, 0)
      # set the current node in the merkle tree to the next hash
      {last_hash, rest_hashes} = List.pop_at(hashes, 0)
      tree = set_current_node(tree, last_hash)
      # go up a level
      updated_tree = up(tree)
      {updated_tree, rest_flags, rest_hashes}
    else
      # get the left hash
      left_hash = get_left_node(tree)
      parse_left_hash(left_hash, tree, flag_bits, hashes)
    end
  end

  def parse_left_hash(:none, tree, flag_bits, hashes) do
    {last_flag, rest_flags} = List.pop_at(flag_bits, 0)

    # if the next flag bit is 0, the next hash is our current node
    if last_flag == 0 do
      {last_hash, rest_hashes} = List.pop_at(hashes, 0)
      # Set the current node to be the last_hash
      tree = set_current_node(tree, last_hash)
      # Sub-tree doesnt need calculation, go up
      updated_tree = up(tree)
      {updated_tree, rest_flags, rest_hashes}
    else
      # go to the left node
      updated_tree = left(tree)
      {updated_tree, rest_flags, hashes}
    end
  end

  def parse_left_hash(left_hash, tree, flag_bits, hashes) do
    if right_exists(tree) do
      right_hash = get_right_node(tree)

      case right_hash do
        # if we dont have the right hash value
        :none ->
          # go to the right node
          updated_tree = right(tree)
          {updated_tree, flag_bits, hashes}

        bin_value ->
          # combine the left and right hashes
          updated_tree = set_current_node(tree, merkle_parent(left_hash, bin_value))
          # we've completed this sub-tree, go up
          updated_tree = up(updated_tree)
          {updated_tree, flag_bits, hashes}
      end
    else
      # combine the left hash twice
      updated_tree = set_current_node(tree, merkle_parent(left_hash, left_hash))
      # we've completed this sub-tree, go up
      updated_tree = up(updated_tree)
      {updated_tree, flag_bits, hashes}
    end
  end

  def merkle_parent(hash_l, hash_r) when is_binary(hash_l) and is_binary(hash_r) do
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
          {nil, parents ++ [parent]}
        else
          {x, parents}
        end
      end)

    result
  end

  def merkle_parent_level(hashes) when is_list(hashes) and rem(length(hashes), 2) != 0 do
    last = List.last(hashes)
    merkle_parent_level(hashes ++ [last])
  end

  def merkle_root(hashes) when length(hashes) == 1 do
    hashes |> Enum.at(0)
  end

  def merkle_root(hashes) do
    merkle_parent_level(hashes) |> merkle_root()
  end
end
