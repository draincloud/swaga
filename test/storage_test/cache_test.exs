defmodule CacheTest do
  use ExUnit.Case

  setup_all do
    Swaga.Storage.Cache.start([])
    on_exit(&Swaga.Storage.Cache.stop/0)
    :ok
  end

  test "add then get v1" do
    addCall = Swaga.Storage.Cache.add_record_v1({"key1", "val1"})
    assert addCall == {:atomic, :ok}

    getCall =  Swaga.Storage.Cache.get_record_v1("key1")
    assert getCall == [{KeyValCacheV1, "key1", "val1"}]
  end
end
