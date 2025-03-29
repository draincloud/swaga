defmodule SignaturePointTest do
  use ExUnit.Case

  test "find uncompressed secp 1" do
    pk = PrivateKey.new(5000)
    p = PrivateKey.extract_point(pk)
    sec = Secp256Point.uncompressed_sec(p)

    assert Base.encode16(sec) ==
             "04FFE558E388852F0120E46AF2D1B370F85854A8EB0841811ECE0E3E03D282D57C315DC72890A4F10A1481C031B03B351B0DC79901CA18A00CF009DBDB157A1D10"
  end

  test "find uncompressed secp 2" do
    pk = PrivateKey.new(2018 ** 5)
    p = PrivateKey.extract_point(pk)
    sec = Secp256Point.uncompressed_sec(p)

    assert Base.encode16(sec) ==
             "04027F3DA1918455E03C46F659266A1BB5204E959DB7364D2F473BDF8F0A13CC9DFF87647FD023C13B4A4994F17691895806E1B40B57F4FD22581A4F46851F3B06"
  end

  test "find uncompressed secp 3" do
    pk = PrivateKey.new(0xDEADBEEF12345)
    p = PrivateKey.extract_point(pk)
    sec = Secp256Point.uncompressed_sec(p)

    assert Base.encode16(sec) ==
             "04D90CD625EE87DD38656DD95CF79F65F60F7273B67D3096E68BD81E4F5342691F842EFA762FD59961D0E99803C61EDBA8B3E3F7DC3A341836F97733AEBF987121"
  end

  test "find the compressed SEC format for the public key where the private key secrets are" do
    pk = PrivateKey.new(5001)
    sec_compressed = Secp256Point.compressed_sec(pk)

    assert Base.encode16(sec_compressed) ==
             "0357A4F368868A8A6D572991E484E664810FF14C05C0FA023275251151FE0E53D1"

    pk = PrivateKey.new(2019 ** 5)
    sec_compressed = Secp256Point.compressed_sec(pk)

    assert Base.encode16(sec_compressed) ==
             "02933EC2D2B111B92737EC12F1C5D20F3233A0AD21CD8B36D0BCA7A0CFA5CB8701"

    pk = PrivateKey.new(0xDEADBEEF54321)
    sec_compressed = Secp256Point.compressed_sec(pk)

    assert Base.encode16(sec_compressed) ==
             "0296BE5B1292F6C856B3C5654E886FC13511462059089CDF9C479623BFCBE77690"
  end

  test "Find the addresses corresponding to the public keys whose private key secrets are:" do
    pk = PrivateKey.new(5002)
    address = Secp256Point.address(pk.point, false, true)
    assert address == "mmTPbXQFxboEtNRkwfh6K51jvdtHLxGeMA"
    pk = PrivateKey.new(2020 ** 5)
    address = Secp256Point.address(pk.point, true, true)
    assert address == "mopVkxp8UhXqRYbCYJsbeE1h1fiF64jcoH"
    pk = PrivateKey.new(0x12345DEADBEEF)
    address = Secp256Point.address(pk.point, true, false)
    assert address == "1F1Pn2y6pDb68E5nYJJeba4TLg2U7B6KF1"
  end
end
