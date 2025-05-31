require Logger

defmodule Base58Test do
  use ExUnit.Case
  require IEx

  test "base58" do
    to_encode = "7C076FF316692A3D7EB3C3BB0F8B1488CF72E1AFCD929E29307032997A838A3D"

    assert "275o5BW2sJT56gnJWj6M5iNxqYxRF9WLQSnKD29Bf4GdVegi5s3UbiVCnZ5M6gtNpyrH2CRSjTmySFT97HJFZF4X" ==
             Base58.encode_from_binary(to_encode)

    to_encode = "EFF69EF2B1BD93A66ED5219ADD4FB51E11A840F404876325A1E8FFE0529A2C"

    assert "58AFzp7e4XN79W4bbrLZ3dhgoCWfRUpqfT1KuSW478SwQjdU7G8YgCJDuGA6XFYh6RxSxHxxCrDJL2wLW3aRp" ==
             Base58.encode_from_binary(to_encode)

    to_encode = "C7207FEE197D27C618AEA621406F6BF5EF6FCA38681D82B2F06FDDBDCE6FEAB6"

    assert "2LwjJQ47MqJbkRta9vxSGNmVC3VLxcMb6ZAoAEBrdEYj74C2X6ST8wFNAqcmCEqSkzUbj4HbNmi1veiAGFJJsKd7" ==
             Base58.encode_from_binary(to_encode)
  end

  test "decode base58" do
    addr = "mnrVtF8DWjMu839VW3rBfgYaAfKk8983Xf"
    h160 = Base58.decode(addr)
    want = "507b27411ccf7f16f10297de6cef3f291623eddf"
    assert h160 === want
  end

  # Mainnet p2sh uses the 0x05 byte, which causes addresses to start with a 3 in Base58
  test "p2sh addresses" do
    h160 = Base.decode16!("74d691da1574e6b3c192ecfb52cc8984ee7b6c56", case: :lower)
    assert "3CLoMMyuoDQTPRD3XYZtCvgvkadrAdvdXh" == Base58.encode_base58_checksum(<<0x05>> <> h160)
  end

  test "xprv encode version" do
    want = "7irrX"
    input = "0488ADE4" |> Base.decode16!(case: :upper)
    assert want == input |> Base58.encode_from_binary()
  end
end
