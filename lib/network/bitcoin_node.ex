require Logger

defmodule BitcoinNode do
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
  def send(%BitcoinNode{socket: socket, testnet: testnet}, msg, module)
      when is_atom(module) do
    serialized_message = module.serialize(msg)
    envelope = NetworkEnvelope.new(module.command(), serialized_message, testnet)
    Logger.debug("Sending #{module.command()}")

    case Socket.send(socket, NetworkEnvelope.serialize(envelope)) do
      ok -> {:ok}
      {:error, error} -> raise "Error sending request #{error}"
    end
  end

  def read(%BitcoinNode{socket: socket, testnet: _testnet}) do
    case Socket.recv(socket) do
      {:error, error} ->
        raise "Error reading from socket, #{inspect(error)}"

      {:ok, data} ->
        Logger.debug("Data from socket #{inspect(NetworkEnvelope.parse(data))}")
        NetworkEnvelope.parse(data)
    end
  end

  def wait_for(%BitcoinNode{} = node, command_to_match, "version" = command_to_match) do
    send(node, %{command: VerAckMessage.command()}, VerAckMessage)
  end

  def wait_for(%BitcoinNode{} = node, command_to_match, "ping" = command_to_match) do
    send(node, %{command: PongMessage.command()}, PongMessage)
  end

  def wait_for(%BitcoinNode{} = node, command_to_match, "verack" = command_to_match) do
    Logger.debug("Received verack message, ignoring")
    %NetworkEnvelope{command: parsed_command} = read(node)
    wait_for(node, parsed_command, command_to_match)
  end

  # loop until the command is found
  def wait_for(%BitcoinNode{} = node, not_eq_command, command_to_match) do
    Logger.debug("No match #{inspect(not_eq_command)} and #{inspect(command_to_match)}")
    %NetworkEnvelope{command: parsed_command} = read(node)
    wait_for(node, parsed_command, command_to_match)
  end

  # Do a handshake with the other node
  # Handshake is sending a version message and getting a VerAck back
  def handshake(%BitcoinNode{} = node) do
    {:ok} = send(node, VersionMessage.new(), VersionMessage)
    %NetworkEnvelope{command: parsed_command} = read(node)
    wait_for(node, parsed_command, VersionMessage.command())
  end
end
