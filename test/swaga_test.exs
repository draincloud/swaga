defmodule SwagaTest do
  use ExUnit.Case
  doctest Swaga

  test "greets the world" do
    assert Swaga.hello() == :world
  end
end
