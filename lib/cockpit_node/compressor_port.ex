defmodule CockpitNode.CompressorPort do
  use GenServer, restart: :permanent
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :compressor_port)
  end

  def init(nil) do
    {:ok, Port.open({:spawn, "compressor"}, [:binary, packet: 2])}
  end

  def handle_info({port, {:data, msg}}) do
    Logger.info("Compressor: #{msg}")

    {:noreply, port}
  end
end