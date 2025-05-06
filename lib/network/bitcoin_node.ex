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
    opts = [:binary, active: :once]
    {:ok, socket} = Socket.start_link(host, port, opts)

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
  def send(%BitcoinNode{socket: socket, testnet: testnet}, %{command: command} = msg, module)
      when is_atom(module) do
    serialized_message = module.serialize(msg)
    envelope = NetworkEnvelope.new(command, serialized_message, testnet)
    Socket.send(socket, NetworkEnvelope.serialize(envelope))
  end

  def read(%BitcoinNode{socket: socket, testnet: _testnet}) do
    bin = Socket.recv(socket)
    NetworkEnvelope.parse(bin)
  end

  #  def wait_for(%Node{}, message_classes) do
  #  end
end
