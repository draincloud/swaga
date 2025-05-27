require Logger

defmodule SocketTest do
  use ExUnit.Case
  @moduletag :network
  # This test might fail due to rate-limit
  test "connect tcp and receive data" do
    # We have to use charlist because of OTP
    host = ~c"ns343680.ip-94-23-21.eu"
    port = 8333
    {:ok, pid} = Socket.start_link(host, port)

    version =
      VersionMessage.new(
        70015,
        0,
        2047,
        0,
        <<0x00, 0x00, 0x00, 0x00>>,
        8333,
        0,
        <<0x00, 0x00, 0x00, 0x00>>,
        8333,
        <<0x5E, 0x89, 0x66, 0x99, 0x16, 0xDB, 0x5F, 0x10>>
      )

    envelope = NetworkEnvelope.new(VersionMessage.command(), VersionMessage.serialize(version))

    assert NetworkEnvelope.serialize(envelope) |> Base.encode16(case: :lower) ==
             "f9beb4d976657273696f6e00000000006e000000597815207f1101000000000000000000ff07000000000000000000000000000000000000000000000000ffff00000000208d000000000000000000000000000000000000ffff00000000208d5e89669916db5f10182f70726f6772616d6d696e67626974636f696e3a302e312f0000000000"

    :ok = Socket.send(pid, NetworkEnvelope.serialize(envelope))

    {:ok, data} = Socket.recv(pid)
    {%{command: command}, _} = NetworkEnvelope.parse(data)

    assert "version" == command
  end
end
