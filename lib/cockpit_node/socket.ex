defmodule CockpitNode.Socket do
    use GenServer, restart: :permanent
    require Logger

    def start_link(_) do
        config = Application.get_env(:cockpit_node, CockpitNode.Socket)
        GenServer.start_link(__MODULE__, config)
    end

    def init(config) do
        port = Keyword.get(config, :port)
        address = to_charlist Keyword.get(config, :address)
        server_id = Keyword.get(config, :server_id)
        api_key = Keyword.get(config, :key)
        :timer.send_after(3000, {:connect, address, port, server_id, api_key})
    end

    def handle_info({:connect, address, port, server_id, api_key}, _state) do
        {:ok, socket} = :gen_tcp.connect(address, port, [:binary, packet: 2, active: :once])
        signature = :crypto.hmac(:sha512, <<server_id::big-unsigned-32>>, to_charlist(api_key), 16)

        :gen_tcp.send(socket, <<server_id::big-unsigned-32, signature::binary>>)
        :timer.send_interval(5000, :ping)
        {:noreply, %{server_id: server_id, key: api_key, socket: socket}}
    end

    def handle_info(:ping, %{socket: socket} = state) do
        Logger.debug("Sending ping to daemon")
        :gen_tcp.send(socket, 'ping')

        {:noreply, state}
    end

    def handle_info({:tcp, socket, _data}, state) do
        :inet.setopts(socket, [active: :once])
        {:noreply, state}
    end

    def handle_info({:tcp_closed, _socket}, state) do
        {:stop, :socket_closed, state}
    end

    def handle_info({:tcp_error, _socket}, state) do
        {:stop, :socket_closed, state}
    end
end