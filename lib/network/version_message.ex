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
            user_agent: "emochka",
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
        user_agent \\ "emochka",
        latest_block \\ 0,
        relay \\ false
      ) do
    message_timestamp =
      if timestamp == nil do
        :os.system_time(:second)
      else
        timestamp
      end

    nonce =
      if nonce == nil do
        Helpers.random_nonce()
      else
        nonce
      end

    %VersionMessage{
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
    network_services_sender = MathUtils.int_to_little_endian(sender_services, 8)
    ser_timestamp = MathUtils.int_to_little_endian(timestamp, 8)
    network_services_receiver = MathUtils.int_to_little_endian(receiver_services, 8)
    # is little endian
    receiver_address = :binary.decode_unsigned(sender_ip)
    ser_receiver_port = :binary.decode_unsigned(receiver_port)
    ser_services_sender_2 = MathUtils.int_to_little_endian(sender_services, 8)
    ser_sender_address = :binary.decode_unsigned(sender_ip)
    ser_nonce = :binary.decode_unsigned(nonce)
    #    ser_user_agent =
  end
end
