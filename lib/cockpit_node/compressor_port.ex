defmodule CockpitNode.CompressorPort do
  use GenServer, restart: :permanent
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :compressor_port)
  end

  def init(nil) do
    {:ok, Port.open({:spawn, "compressor"}, [:binary, packet: 2])}
  end

  def handle_info({_port, {:data, <<2, pps::big-unsigned-64>>}}, state) do
    Logger.info("Compressor PPS: #{pps}")
    send :cockpit_socket, {:pps_update, pps}
    
    {:noreply, state}
  end

  def handle_info({_port, {:data, msg}}, state) do
    Logger.info("Compressor: #{msg}")

    {:noreply, state}
  end

  def handle_info({:server_update, update}, state) do
    {:noreply, state}
  end
end