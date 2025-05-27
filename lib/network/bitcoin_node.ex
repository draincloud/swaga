defmodule BitcoinNode do
  @moduledoc """
  Represents a connection to a Bitcoin node.

  This module handles establishing a TCP connection, sending/receiving
  Bitcoin network messages (wrapped in `NetworkEnvelope`), and performing
  the initial handshake. It aims to provide a basic interface for
  interacting with the Bitcoin peer-to-peer network.
  """
  require Logger
  # Define the structure for holding node connection state.
  @type t :: %__MODULE__{
          host: charlist(),
          port: non_neg_integer(),
          testnet: boolean(),
          # Depending on your Socket implementation
          socket: :inet.socket()
        }
  @enforce_keys [
    :host,
    :port,
    :testnet,
    :socket
  ]

  defstruct [
    :host,
    :port,
    :testnet,
    :socket
  ]

  @doc """
  Creates a new BitcoinNode and attempts to establish a connection.

  Defaults to a public node if `host` is not provided.
  Resolves the port based on the network (mainnet/testnet) if not provided.

  ## Returns
    - `%BitcoinNode{}` if the connection is successful.
    - `{:error, reason}` if the connection fails.
  """
  def new(
        host \\ ~c"bitcoin-rpc.publicnode.com",
        port \\ nil,
        testnet \\ false
      )
      when is_list(host) do
    resolved_port = resolve_port(port, testnet)

    case Socket.start_link(host, resolved_port) do
      {:ok, socket} ->
        Logger.info("Connection successful.")

        node = %BitcoinNode{
          host: host,
          port: resolved_port,
          testnet: testnet,
          socket: socket
        }

        node

      {:error, reason} ->
        Logger.error("Connection failed: #{inspect(reason)}")
        {:error, {:socket_start_failed, reason}}
    end
  end

  defp resolve_port(port, _testnet) when is_integer(port), do: port
  defp resolve_port(nil, true), do: 18_333
  defp resolve_port(nil, false), do: 8_333

  @doc """
  Sends a structured message to the connected Bitcoin node.

  It serializes the message, wraps it in a `NetworkEnvelope`, and sends it
  over the socket.

  ## Parameters
    - node: The `BitcoinNode` instance.
    - msg: The message structure to send (e.g., `%VersionMessage{}`).
    - module: The module responsible for serializing `msg` and providing the command.
    - command: Optional override for the network command string.

  ## Returns
    - `:ok` if successful.
    - `{:error, reason}` on failure.
  """
  def send(%BitcoinNode{socket: socket}, msg, module, command \\ nil)
      when is_atom(module) do
    serialized_message = module.serialize(msg)

    network_command =
      if command == nil do
        module.command()
      else
        command
      end

    envelope = NetworkEnvelope.new(network_command, serialized_message)
    Logger.debug("Sending #{inspect(envelope)}")

    Logger.debug("Sending #{inspect(NetworkEnvelope.serialize(envelope) |> Base.encode16())}")

    case Socket.send(socket, NetworkEnvelope.serialize(envelope)) do
      :ok -> {:ok}
      {:error, error} -> raise "Error sending request #{error}"
    end
  end

  @doc """
  Reads and parses a single `NetworkEnvelope` from the socket.

  It handles TCP stream buffering, reading data until a complete message
  can be parsed.

  ## Parameters
    - node: The `BitcoinNode` instance.
    - buffer: Internal buffer for partial messages (defaults to `<<>>`).
    - timeout: Socket receive timeout in milliseconds.

  ## Returns
    - `{:ok, %NetworkEnvelope{}, binary()}`: Parsed envelope and any remaining data.
    - `{:error, reason}` on failure.
  """
  def read(
        %BitcoinNode{socket: socket} = node,
        buffer \\ <<>>,
        do_parse \\ true,
        timeout \\ 10_000
      ) do
    case Socket.recv(socket, 0, timeout) do
      {:error, error} ->
        raise "Error reading from socket, #{inspect(error)}"

      {:ok, data} ->
        #        Logger.debug("Data from socket #{inspect(:binary.bin_to_list(data))}")

        if do_parse do
          case NetworkEnvelope.parse(buffer <> data) do
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
  def wait_for(node, parsed_envelopes, required_command, buffer \\ "") do
    {network, rest_bin} = read(node, buffer, true)
    parsed = parsed_envelopes ++ [network]

    case Enum.find(parsed, fn env -> env.command == required_command end) do
      nil ->
        wait_for(node, parsed, required_command, rest_bin)

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
    _command = wait_for(node, [], VersionMessage.command())
    {:ok} = send(node, VerAckMessage.new(), VerAckMessage)
    :ok
  end
end
