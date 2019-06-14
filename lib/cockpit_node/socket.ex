defmodule CockpitNode.Socket do
    use GenServer, restart: :permanent
    use CockpitNode.EncryptedSocket

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

    def handle_info(:ping, state) do
        Logger.debug("Sending ping to daemon")
        send_encrypted('ping', state)

        {:noreply, state}
    end
    
    def handle_info({:decrypted, "pong"}, state) do
        Logger.debug("Received pong from daemon")

        {:noreply, state}
    end

    def handle_info({:decrypted, data}, state) do
        msg = :erlang.binary_to_term(data)
        case msg do
            {:sever_update, msg_body} ->
                send :compressor_port, msg_body
        end

        {:noreply, state}
    end
end