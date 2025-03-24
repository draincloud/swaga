defmodule Swaga do
  @moduledoc """
  Documentation for `Swaga`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Swaga.hello()
      :world

  """
  def sum_list(xs) do
    case xs do
      [] -> 0
      [h | t] -> h + sum_list(t)
    end
  end

  def test_sum() do
    sum_list([1, 2, 3, 4, 5, 6])
  end

  def print_book(book_map) do
    IO.puts("The book '#{book_map.title}' by '#{book_map.author}' has '#{book_map.pages}'")
  end

  book_map = %{title: "Elixir in Action", author: "Saša Jurić", pages: "228"}

  def reverse_string(str) do
    #
    case str do
      "" ->
        ""

      <<first_char::utf8, rest::binary>> ->
        reverse_string(rest) <> String.at(str, 0)
    end
  end

  def add(a, b) do
    IO.puts("a, b")
  end

  def hello do
    rev = reverse_string("")
    IO.puts(rev)
    :world
  end

  def ec do
    FieldElement.new(100, 10)
  end

  def ec_eq do
    f1 = FieldElement.new(3, 31)
    f2 = FieldElement.new(24, 31)
    #    FieldElement.equal?(f1, f2)
    #    FieldElement.add(f1, f2)
    #    FieldElement.sub(f1, f2)
    #    FieldElement.mul(f1, f2)
    FieldElement.div(f1, f2)
  end
end
