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
      {:error, error} -> {:error, "Error sending request #{error}"}
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
        timeout \\ 10_000
      ) do
    case NetworkEnvelope.parse(buffer) do
      {:ok, network, <<>>} ->
        {:ok, network}

      {:ok, network, rest_binary} ->
        {:ok, network, rest_binary}

      {:error, _} ->
        case Socket.recv(socket, 0, timeout) do
          {:ok, <<>>} ->
            {:error, :socket_empty_data}

          {:ok, data} ->
            read(node, buffer <> data, timeout)

          {:error, error} ->
            {:error, error}
        end
    end
  end

  @doc """
  Waits for a specific command message from the node.

  It continuously reads messages using `read/3` until a message with
  the `required_command` is found.

  ## Parameters
    - node: The `BitcoinNode` instance.
    - required_command: The command string (e.g., `"verack"`) to wait for.
    - buffer: Internal buffer (defaults to `<<>>`).
    - timeout: Timeout per read attempt.

  ## Returns
    - `{:ok, %NetworkEnvelope{}, binary()}`: The found envelope and any remaining data.
    - `{:error, reason}` on failure.
  """
  def wait_for(node, required_command, buffer \\ <<>>) do
    case read(node, buffer) do
      {:ok, envelope, rest_bin} ->
        if envelope.command == required_command do
          {:ok, envelope, rest_bin}
        else
          Logger.debug("Received #{envelope.command}, waiting for #{required_command}...")
          wait_for(node, required_command, rest_bin)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Performs the Bitcoin P2P handshake.

  Sends a `VersionMessage`, waits for the peer's `VersionMessage`, sends
  a `VerAckMessage`, and waits for the peer's `VerAckMessage`.

  ## Parameters
    - node: The `BitcoinNode` instance.

  ## Returns
    - `:ok` if successful.
    - `{:error, reason}` on failure.
  """
  def handshake(%BitcoinNode{} = node) do
    with {:ok} <- send(node, VersionMessage.new(), VersionMessage),
         {:ok, _version_msg, rest1} <- wait_for(node, VersionMessage.command()),
         {:ok} <- send(node, VerAckMessage.new(), VerAckMessage),
         {:ok, _verack_msg, <<>>} <- wait_for(node, VerAckMessage.command(), rest1) do
      {:ok}
    else
      {:error, reason} -> {:error, {:handshake_failed, reason}}
    end
  end
end
