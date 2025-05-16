require Logger

defmodule BitcoinNode do
  require IEx

  @enforce_keys [
    :host,
    :port,
    :testnet,
    :logging,
    :socket
  ]

  defstruct [
    :host,
    :port,
    :testnet,
    :logging,
    :socket
  ]

  def new(
        host \\ ~c"bitcoin-rpc.publicnode.com",
        port \\ nil,
        testnet \\ false,
        logging \\ false
      ) do
    {:ok, socket} = Socket.start_link(host, port)

    resolved_port =
      cond do
        port != nil -> port
        testnet -> 18333
        true -> 8333
      end

    %BitcoinNode{
      host: host,
      port: resolved_port,
      testnet: testnet,
      logging: logging,
      socket: socket
    }
  end

  # Sends message, must implement the interface
  def send(%BitcoinNode{socket: socket, testnet: false}, msg, module, command \\ nil)
      when is_atom(module) do
    serialized_message = module.serialize(msg)

    network_command =
      if command == nil do
        module.command()
      else
        command
      end

    #    IEx.pry()

    envelope = NetworkEnvelope.new(network_command, serialized_message)
    #    IEx.pry()
    Logger.debug("Sending #{inspect(envelope)}")

    Logger.debug("Sending #{inspect(NetworkEnvelope.serialize(envelope) |> Base.encode16())}")

    case Socket.send(socket, NetworkEnvelope.serialize(envelope)) do
      :ok -> {:ok}
      {:error, error} -> raise "Error sending request #{error}"
    end
  end

  def read(
        %BitcoinNode{socket: socket, testnet: _testnet} = node,
        prev_bin \\ "",
        do_parse \\ true,
        bytes \\ 0,
        timeout \\ 10000
      ) do
    case Socket.recv(socket, bytes, timeout) do
      {:error, error} ->
        raise "Error reading from socket, #{inspect(error)}"

      {:ok, data} ->
        #        Logger.debug("Data from socket #{inspect(:binary.bin_to_list(data))}")

        if do_parse do
          case NetworkEnvelope.parse(prev_bin <> data) do
            # If we get an error, we read again
            {:missing_payload_size, errored_data} ->
              read(node, errored_data)

            # If it's correctly parsed, then we return it
            network ->
              Logger.debug("Parsed data #{inspect(network)}")
              network
          end
        else
          data
        end
    end
  end

  # Maybe remove parsed_envelopes now
  def wait_for(node, parsed_envelopes, required_command, prev_bin \\ "", timeout \\ 10000) do
    {network, rest_bin} = read(node, prev_bin, true, 0, timeout)
    parsed = parsed_envelopes ++ [network]

    case Enum.find(parsed, fn env -> env.command == required_command end) do
      nil ->
        wait_for(node, parsed, required_command, rest_bin, timeout)

      envelope ->
        Logger.debug("Parsed envelopes #{inspect(parsed)}")
        Logger.debug("rest_bin #{inspect(rest_bin)}")

        if rest_bin != <<>> do
          rest_parsed = NetworkEnvelope.parse(rest_bin)
          Logger.debug("Parsed from rest_bin #{inspect(rest_parsed)}")
        else
          envelope
        end
    end
  end

  # Do a handshake with the other node
  # Handshake is sending a version message and getting a VerAck back
  def handshake(%BitcoinNode{} = node) do
    {:ok} = send(node, VersionMessage.new(), VersionMessage)
    # So we're reading version and verack message from the node
    #    command = wait_for(node, [], VersionMessage.command())
    # match with verack command, payload must be empty and rest_bin as well
    command = wait_for(node, [], VersionMessage.command())
    {:ok} = send(node, VerAckMessage.new(), VerAckMessage)
    :ok
  end
end
