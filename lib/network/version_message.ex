require Logger

defmodule VersionMessage do
  @enforce_keys [
    :version,
    :services,
    :timestamp,
    :receiver_services,
    :receiver_ip,
    :receiver_port,
    :sender_services,
    :sender_ip,
    :sender_port,
    :nonce,
    :user_agent,
    :latest_block,
    :relay
  ]

  defstruct version: 70015,
            services: 0,
            timestamp: nil,
            receiver_services: 0,
            receiver_ip: <<0x00, 0x00, 0x00, 0x00>>,
            receiver_port: 8333,
            sender_services: 0,
            sender_ip: <<0x00, 0x00, 0x00, 0x00>>,
            sender_port: 8333,
            nonce: nil,
            user_agent: "/programmingbitcoin:0.1/",
            latest_block: 0,
            relay: false

  def new(
        version \\ 70015,
        services \\ 0,
        timestamp \\ nil,
        receiver_services \\ 0,
        receiver_ip \\ <<0x00, 0x00, 0x00, 0x00>>,
        receiver_port \\ 8333,
        sender_services \\ 0,
        sender_ip \\ <<0x00, 0x00, 0x00, 0x00>>,
        sender_port \\ 8333,
        nonce \\ nil,
        user_agent \\ "/programmingbitcoin:0.1/",
        latest_block \\ 0,
        relay \\ false
      ) do
    message_timestamp =
      if timestamp == nil do
        :os.system_time(:second)
      else
        timestamp
      end

    message_nonce =
      if nonce == nil do
        Helpers.random_nonce()
      else
        nonce
      end

    %VersionMessage{
      version: version,
      services: services,
      timestamp: message_timestamp,
      receiver_services: receiver_services,
      receiver_ip: receiver_ip,
      receiver_port: receiver_port,
      sender_services: sender_services,
      sender_ip: sender_ip,
      sender_port: sender_port,
      nonce: message_nonce,
      user_agent: user_agent,
      latest_block: latest_block,
      relay: relay
    }
  end

  def serialize(%VersionMessage{
        version: version,
        services: services,
        timestamp: timestamp,
        receiver_services: receiver_services,
        receiver_ip: receiver_ip,
        receiver_port: receiver_port,
        sender_services: sender_services,
        sender_ip: sender_ip,
        sender_port: sender_port,
        nonce: nonce,
        user_agent: user_agent,
        latest_block: latest_block,
        relay: relay
      }) do
    protocol_version = MathUtils.int_to_little_endian(version, 4)
    network_services = MathUtils.int_to_little_endian(services, 8)
    ser_timestamp = MathUtils.int_to_little_endian(timestamp, 8)
    ser_result = protocol_version <> network_services <> ser_timestamp
    # receiver
    network_services_receiver = MathUtils.int_to_little_endian(receiver_services, 8)
    ip_v4_receiver_address = Helpers.ip_v4(receiver_ip)
    ser_receiver_port = <<receiver_port::unsigned-big-integer-16>>

    ser_result =
      ser_result <> network_services_receiver <> ip_v4_receiver_address <> ser_receiver_port

    # sender
    ser_services_sender = MathUtils.int_to_little_endian(sender_services, 8)
    ip_v4_sender_address = Helpers.ip_v4(sender_ip)
    ser_sender_port = <<sender_port::unsigned-big-integer-16>>
    ser_result = ser_result <> ser_services_sender <> ip_v4_sender_address <> ser_sender_port
    # nonce + UserAgent
    ser_result = ser_result <> nonce <> Tx.encode_varint(byte_size(user_agent)) <> user_agent
    # Latest block is 4 bytes
    ser_result = ser_result <> MathUtils.int_to_little_endian(latest_block, 4)

    if relay do
      ser_result <> <<0x01>>
    else
      ser_result <> <<0x00>>
    end
  end
end
