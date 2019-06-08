defmodule CockpitNode.Socket do
    use GenServer, restart: :permanent

    def start_link(_) do
        config = Application.get_env(:cockpit_node, CockpitNode.Socket)
        GenServer.start_link(__MODULE__, config)
    end

    def init(config) do
        port = Keyword.get(config, :port)
        address = to_charlist Keyword.get(config, :address)

        :gen_tcp.connect(address, port, [:binary, packet: 2, active: :once])
    end

    def handle_info({:tcp, socket, data}, _state) do
        :inet.setopts(socket, [active: :once])
        {:noreply, socket}
    end

    def handle_info({:tcp_closed, socket}, _state) do
        {:stop, :socket_closed, socket}
    end

    def handle_info({:tcp_error, socket}, _state) do
        {:stop, :socket_closed, socket}
    end
end