## MerkleTree Module Overview

### The MerkleTree module implements:

- Tree setup: allocate a 2D grid of :none placeholders, sized by the number of leaves.

- Cursor movement: up/1, left/1, right/1 walk a pointer through the tree.

- Accessors: get or set the hash at the cursor, or peek at child slots.

- Population: given a list of flag_bits and a list of hashes, reconstruct the Merkle root.

- Helpers: combine pairs of hashes into parent hashes, handling odd counts by duplication

## Data Structure and Initialization

```elixir

defmodule MerkleTree do
require Logger

# Enforce that every struct has these fields:
#   :total         – total number of leaves
#   :max_depth     – height of tree (ceil(log2(total)))
#   :nodes         – list-of-lists of placeholders or computed hashes
#   :current_depth – cursor: which level we’re on (0 = root)
#   :current_index – cursor: which position in that level
@enforce_keys [:total, :max_depth, :nodes, :current_depth, :current_index]
defstruct [:total, :max_depth, :nodes, :current_depth, :current_index]

@doc """
Build an empty tree for `total_leaves` items.
- Compute `max_depth = ceil(log2(total_leaves))`
- For each level `i` from 0 (root) to max_depth (leaves), allocate
  `ceil(total_leaves / 2^(max_depth - i))` slots, all initialized to `:none`.
- Set cursor at depth 0, index 0.
  """
  def new(total_leaves) when is_integer(total_leaves) do
  # 1. Compute maximum depth of a full binary tree for `total_leaves`
  max_depth =
  total_leaves
  |> :math.log2()
  |> Float.ceil()
  |> round()

  # 2. Build each level’s list of placeholders
  nodes =
  0..max_depth
  |> Enum.with_index()
  |> Enum.reduce([], fn {level, _}, acc ->
  # number of slots at this level:
  #   ceil(total_leaves / 2^(max_depth - level))
  num_items =
  total_leaves
  |> Kernel./(:math.pow(2, max_depth - level))
  |> Float.ceil()
  |> round

      acc ++ [ List.duplicate(:none, num_items) ]
  end)

  %MerkleTree{
  total: total_leaves,
  max_depth: max_depth,
  nodes: nodes,
  current_depth: 0,
  current_index: 0
  }
  end
end
```

- Why duplicate the last slot?
  When you later combine at each level, odd numbers of children get “folded” by duplicating the last hash.

### Cursor Movement: up/1, left/1, right/1

We walk the tree by adjusting current_depth and current_index—but never go above root:

```elixir
# If we’re already at the root (depth 0), stay there
def up(%MerkleTree{current_depth: 0} = tree), do: tree

# Otherwise, move up one level: depth–1, index = floor(index/2)
def up(%MerkleTree{current_depth: depth, current_index: idx} = tree)
    when depth > 0 and idx >= 0 do
  %MerkleTree{tree | current_depth: depth - 1, current_index: div(idx, 2)}
end

# Descend to left child: depth+1, index*2
def left(%MerkleTree{current_depth: depth, current_index: idx} = tree)
    when depth >= 0 and idx >= 0 do
  %MerkleTree{tree | current_depth: depth + 1, current_index: idx * 2}
end

# Descend to right child: depth+1, index*2 + 1
def right(%MerkleTree{current_depth: depth, current_index: idx} = tree)
    when depth >= 0 and idx >= 0 do
  %MerkleTree{tree | current_depth: depth + 1, current_index: idx * 2 + 1}
end

```

### Accessors and Mutators

```elixir
# Return the root slot (nodes[0][0])
def root(%MerkleTree{nodes: nodes}), do: nodes |> hd() |> hd()

# Overwrite the hash at the cursor position
def set_current_node(%MerkleTree{nodes: nodes, current_depth: d, current_index: i} = tree, node) do
  new_nodes =
    List.update_at(nodes, d, fn row ->
      List.replace_at(row, i, node)
    end)

  %MerkleTree{tree | nodes: new_nodes}
end

# Peek where the cursor is
def get_current_node(tree), do: tree.nodes |> Enum.at(tree.current_depth) |> Enum.at(tree.current_index)

# Peek left child slot (depth+1, index*2)
def get_left_node(tree),  do: tree.nodes |> Enum.at(tree.current_depth + 1) |> Enum.at(tree.current_index * 2)

# Peek right child slot (depth+1, index*2 +1)
def get_right_node(tree), do: tree.nodes |> Enum.at(tree.current_depth + 1) |> Enum.at(tree.current_index * 2 + 1)

# Am I at a leaf level?
def is_leaf(%MerkleTree{current_depth: d, max_depth: m}), do: d == m

# Does this node have a right child index in bounds?
def right_exists(tree) do
  tree.nodes
  |> Enum.at(tree.current_depth + 1)
  |> length() > tree.current_index * 2 + 1
end
```

## Populating the Tree

### We drive a pre-order walk, guided by flag_bits and consuming from hashes.

1 → “descend into this subtree”

0 → “consume one hash as this subtree’s value, skip children”

```elixir
@doc """
Given a tree with all slots = :none, plus:
  - flag_bits: list of 0/1 decisions (pre-order)
  - hashes:    list of leaf or subtree hashes
Populates every slot and finally returns the Merkle root binary.
"""
def populate_tree(tree, flag_bits, hashes) do
  case root(tree) do
    :none ->
      # still missing the root → parse one step
      {tree2, fb2, h2} = parse_tree(tree, flag_bits, hashes)
      populate_tree(tree2, fb2, h2)

    actual_root when is_binary(actual_root) ->
      # done: ensure we consumed every bit & hash
      if fb2 == [] and h2 == [] do
        actual_root
      else
        raise "didn't consume everything"
      end
  end
end
```

## Putting It All Together

- Initialize with MerkleTree.new(total_leaves).

- Parse flags & hashes via populate_tree(tree, flag_bits, hashes).

- Get resulting root binary.

This module mirrors the classic partial Merkle‐tree proof algorithm used by SPV Bitcoin clients: your flag_bits decide
where to recurse, and your hashes supply either leaves or entire subtree hashes.
By the end of populate_tree/3, you’ll have reconstructed the exact Merkle root.


