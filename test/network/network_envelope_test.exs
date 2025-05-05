defmodule NetworkEnvelopeTest do
  use ExUnit.Case

  test "parse network message" do
    message = Base.decode16!("f9beb4d976657261636b000000000000000000005df6e0e2", case: :lower)
    network = NetworkEnvelope.parse(message)
    assert network.command == "verack"
    assert network.payload == ""
  end

  test "bitcoin network version message" do
    msg =
      Base.decode16!(
        "f9beb4d976657273696f6e0000000000650000005f1a69d2721101000100000000000000bc8f5e5400000000010000000000000000000000000000000000ffffc61b6409208d010000000000000000000000000000000000ffffcb0071c0208d128035cbc97953f80f2f5361746f7368693a302e392e332fcf05050001",
        case: :lower
      )

    <<_::binary-size(24), payload::binary>> = msg
    network = NetworkEnvelope.parse(msg)
    assert network.command == "version"
    assert network.payload == payload
  end

  test "serialize" do
    want =
      "f9beb4d976657273696f6e0000000000650000005f1a69d2721101000100000000000000bc8f5e5400000000010000000000000000000000000000000000ffffc61b6409208d010000000000000000000000000000000000ffffcb0071c0208d128035cbc97953f80f2f5361746f7368693a302e392e332fcf05050001"

    msg =
      Base.decode16!(
        want,
        case: :lower
      )

    network = NetworkEnvelope.parse(msg)
    assert want == Base.encode16(NetworkEnvelope.serialize(network), case: :lower)
  end
end
