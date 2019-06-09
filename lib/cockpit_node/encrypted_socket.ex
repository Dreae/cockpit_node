defmodule CockpitNode.EncryptedSocket do
  require Logger

  defmacro __using__(_opts) do
    quote do
      import CockpitNode.EncryptedSocket
      
      def handle_info({:connect, _, _, _, _} = msg, state), do: CockpitNode.EncryptedSocket.handle_info(msg, state)
      def handle_info({:tcp, _client, _data} = msg, state), do: CockpitNode.EncryptedSocket.handle_info(msg, state)
      def handle_info({:tcp_closed, _client} = msg, state), do: CockpitNode.EncryptedSocket.handle_info(msg, state)
      def handle_info({:tcp_error, _client} = msg, state), do: CockpitNode.EncryptedSocket.handle_info(msg, state)
    end
  end

  def send_encrypted(data, %{socket: socket, server_id: server_id, session_key: session_key}) do 
    iv = :crypto.strong_rand_bytes(12)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:chacha20_poly1305, session_key, iv, data, <<server_id::big-unsigned-32>>, 16, true)
    :gen_tcp.send(socket, iv <> tag <> ciphertext)
  end

  def handle_info({:connect, address, port, server_id, api_key}, _state) do
    {:ok, socket} = :gen_tcp.connect(address, port, [:binary, packet: 2, active: :once])
    Logger.debug("Connected to cockpit daemon, starting key exchange")
    {public_key, private_key} = :crypto.generate_key(:ecdh, :prime256v1)
    iv = :crypto.strong_rand_bytes(12)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:chacha20_poly1305, api_key, iv, public_key, <<server_id::big-unsigned-32>>, 16, true)

    :gen_tcp.send(socket, <<server_id::big-unsigned-32>> <> iv <> tag <> ciphertext)
    {:noreply, %{server_id: server_id, key: api_key, socket: socket, private_key: private_key}}
  end

  def handle_info({:tcp, socket, data}, %{key: api_key, private_key: private_key, server_id: server_id} = state) do
    :inet.setopts(socket, [active: :once])
    <<iv::binary-size(12), tag::binary-size(16), ciphertext::binary>> = data
    <<public_key::binary-size(65)>> = :crypto.crypto_one_time_aead(:chacha20_poly1305, api_key, iv, ciphertext, <<server_id::big-unsigned-32>>, tag, false)

    session_key = :crypto.compute_key(:ecdh, public_key, private_key, :prime256v1)
    Logger.debug("Key exchange complete")
    Logger.info("Connected to cockpit daemon")
    :timer.send_interval(5000, :ping)

    state = state 
      |> Map.put(:session_key, :crypto.hash(:sha512, session_key))
      |> Map.delete(:public_key)
      |> Map.delete(:private_key)
    {:noreply, %{state | socket: socket}}
  end

  def handle_info({:tcp, socket, data}, %{server_id: server_id, session_key: session_key} = state) do
    :inet.setopts(socket, [active: :once])

    <<iv::binary-size(12), tag::binary-size(16), ciphertext::binary>> = data
    <<body::binary>> = :crypto.crypto_one_time_aead(:chacha20_poly1305, session_key, iv, ciphertext, <<server_id::big-unsigned-32>>, tag, false)
    send self(), {:decrypted, body}

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :socket_closed, state}
  end

  def handle_info({:tcp_error, _socket}, state) do
    {:stop, :socket_closed, state}
  end
end