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
      :ok -> {:ok}
      {:error, error} -> raise "Error sending request #{error}"
    end
  end

  def read(%BitcoinNode{socket: socket, testnet: _testnet}, bytes \\ 0) do
    case Socket.recv(socket, bytes) do
      {:error, error} ->
        raise "Error reading from socket, #{inspect(error)}"

      {:ok, data} ->
        Logger.debug("Data from socket #{inspect(data)}")
        Logger.debug("Data from socket #{inspect(NetworkEnvelope.parse(data))}")
        NetworkEnvelope.parse(data)
    end
  end

  # 2 args, to start recursive_process
  def read_while(node, parsed_envelopes, required_command) do
    Logger.debug("parsed_envelopes #{inspect(parsed_envelopes)}")
    {network, rest_bin} = read(node)
    Logger.debug("72:rest_bin #{inspect(rest_bin)}")
    read_while(node, parsed_envelopes ++ [network], required_command, rest_bin)
  end

  # return array if found
  def read_while(node, parsed_envelopes, required_command, "") do
    case Enum.find(parsed_envelopes, fn env -> env.command == required_command end) do
      nil ->
        read_while(node, parsed_envelopes, required_command)

      _envelope ->
        parsed_envelopes
    end
  end

  # if rest_bin not empty string, parse only rest_bin
  def read_while(node, parsed_envelopes, required_command, rest) do
    {network, rest_bin} = NetworkEnvelope.parse(rest)
    Logger.debug("90:rest #{inspect(rest_bin)}")
    read_while(node, parsed_envelopes ++ [network], required_command, rest_bin)
  end

  #  # This is the general case, where last arg is empty string,
  #  # it means that we did read all socket bytes,
  #  # so we have to read now
  #  def wait_for(%BitcoinNode{} = node, required_command, module, rest_bin) do
  #    {%NetworkEnvelope{command: command, payload: payload}, rest_bin} = BitcoinNode.read(node, 80)
  #
  #    if command == required_command do
  #      Logger.debug("75: No match #{inspect(required_command)} and #{inspect(command)}")
  #      module.parse(payload)
  #    else
  #      wait_for(node, required_command, module, rest_bin)
  #    end
  #  end

  #  def wait_for(%BitcoinNode{} = node, required_command, module, not_empty_binary) do
  #    {%NetworkEnvelope{command: command, payload: payload}, rest_bin} =
  #      NetworkEnvelope.parse(not_empty_binary)
  #
  #    if command == required_command do
  #      module.parse(payload)
  #    else
  #      Logger.debug("87: No match #{inspect(required_command)} and #{inspect(command)}")
  #      wait_for(node, required_command, module, rest_bin)
  #    end
  #  end

  #  def wait_for(%BitcoinNode{} = node, required_command, module, rest_bin) do
  #    {%NetworkEnvelope{command: command, payload: payload}, rest_bin} = BitcoinNode.read(node)
  #
  #    if command == required_command do
  #      module.parse(payload)
  #    else
  #      wait_for(node, required_command, module, rest_bin)
  #    end
  #  end

  # On version we send out VerAck message
  def parse_command(%BitcoinNode{} = node, command_to_match, "version" = command_to_match) do
    send(node, %{command: VerAckMessage.command()}, VerAckMessage)
  end

  def parse_command(%BitcoinNode{} = node, command_to_match, "ping" = command_to_match) do
    send(node, %{command: PongMessage.command()}, PongMessage)
  end

  def parse_command(%BitcoinNode{}, command_to_match, "verack" = command_to_match) do
    Logger.debug("Received verack message, ignoring")
    {:ok}
  end

  def parse_command(%BitcoinNode{}, command_to_match, "getheaders" = command_to_match) do
    Logger.debug("Received getheaders message, ignoring")
    {:ok}
  end

  # loop until the command is found
  def parse_command(%BitcoinNode{} = node, not_eq_command, command_to_match) do
    Logger.debug("No match #{inspect(not_eq_command)} and #{inspect(command_to_match)}")
    {%NetworkEnvelope{command: parsed_command}, _rest_bin} = read(node)
    parse_command(node, parsed_command, command_to_match)
  end

  # Do a handshake with the other node
  # Handshake is sending a version message and getting a VerAck back
  def handshake(%BitcoinNode{} = node) do
    {:ok} = send(node, VersionMessage.new(), VersionMessage)
    # So we're reading version and verack message from the node
    {%NetworkEnvelope{command: "version"}, rest_bin} = read(node)
    # match with verack command, payload must be empty and rest_bin as well
    {%NetworkEnvelope{command: "verack", payload: ""}, ""} =
      NetworkEnvelope.parse(rest_bin)

    {:ok} = send(node, VerAckMessage.new(), VerAckMessage)
    :ok
  end
end
