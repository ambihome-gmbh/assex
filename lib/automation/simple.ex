defmodule Automation.Simple do
  use GenServer

  def new(_config) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(config) do
    Phoenix.PubSub.subscribe(:event_pubsub, "trigger")
    {:ok, config}
  end

  @impl GenServer
  def handle_info({:trigger, %{from: from_entity, data: data}}, state) do
    # credo:disable-for-next-line
    IO.inspect({from_entity.id, data}, label: :automation_trigger)

    {:noreply, state}
  end
end
