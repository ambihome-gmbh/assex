defmodule Entity do
  @moduledoc """
  A behaviour module for implementing an Entity.

  An Entity represents a device or service in the real world.

  An entity (example: the wall lamp in the kitchen)

  - belongs to a domain (the wall lamp belongs to the `light` domain)
  - is located in an area (kitchen)
  - has a state (the light can be `on` or `off`)
  - it keeps track of its state (someone may turn on the wall-lamp using a light-switch)
    - this may be done by polling the state of the device (see `@callback do_poll` and its implementation in the [File Entity](lib/entity/file.ex))
    - or (better, if possible) the entity reacts to pushed state changes (e.g. the Hue Bridge pushes state changes using SSE)
  - when the state changes, the entity fires a `state-changed` event on the event-bus. See `update_state/2' (This is called the "state-machine" in HASS)
  - it may offer services (`turn_on`, `turn_off`)

  On creation (`new/4`)

  - the entity is registered in `Registry.Entities` and can be found there using `:via`.
  - written to Mnesia (using Memento)
  - a `state-changed` event is fired on the event-bus

  The `do_poll` callback is called with the given interval (or not, if no interval given)

  On receive of a `service-call` event the `service_call/3`-callback is called. (see [Service.Call](lib/service/call.ex))

  On a state change the implementing entity has to call `update_state/2` (see [do_poll in File Entity](lib/entity/file.ex)).
  `update_state/2` will check if the state has changed and if so, update the entity in the DB and also fire an event.

  """

  use Memento.Table,
    attributes: [:id, :name, :domain, :area, :state],
    index: [:domain, :area]

  alias Phoenix.PubSub

  @type id :: String.t()
  @type t() :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          domain: String.t(),
          area: String.t(),
          state: any()
        }

  @callback service_call(atom(), [any()], %Entity{}) :: {atom(), any}
  @callback do_poll(%Entity{}) :: %Entity{}
  @callback on_state_changed(%Entity{}, any()) :: any()

  @optional_callbacks do_poll: 1

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer
      @behaviour Entity
      # TODO how can dialyzer work with @poll_interval ??
      @dialyzer {:nowarn_function, init: 1}

      @poll_interval Keyword.get(opts, :poll_interval)

      def do_poll(entity) do
        entity
      end

      def on_state_changed(_entity, new_state) do
        new_state
      end

      defoverridable do_poll: 1
      defoverridable on_state_changed: 2

      def new(name, domain, area, initial_state \\ :off) do
        entity = %Entity{
          id: Assex.get_unique_id(Entity, [domain, name]),
          name: name,
          domain: domain,
          area: area,
          state: initial_state
        }

        GenServer.start_link(__MODULE__, entity,
          name: {:via, Registry, {Registry.Entities, entity.id}}
        )
      end

      @impl GenServer

      def init(entity) do
        update_entity!(entity)

        if @poll_interval do
          :timer.send_interval(@poll_interval, :poll)
        end

        {:ok, entity}
      end

      defp update_entity!(entity) do
        Memento.transaction!(fn -> Memento.Query.write(entity) end)
        # TODO use fire/2 ?
        PubSub.broadcast(:event_pubsub, "state-changed", {:state_change, entity})
      end

      @impl GenServer
      def handle_cast({:service_call, service, args}, entity) do
        entity =
          case service_call(service, args, entity) do
            {:ok, new_entity} ->
              new_entity

            {:error, msg} ->
              # credo:disable-for-next-line
              IO.inspect(msg, label: :error)
              entity
          end

        {:noreply, entity}
      end

      @impl GenServer
      def handle_call({:service_call, service, args}, _from, entity) do
        {reply, entity} =
          case service_call(service, args, entity) do
            {:ok, new_entity} -> {:ok, new_entity}
            error -> {error, entity}
          end

        {:reply, reply, entity}
      end

      @impl GenServer
      def handle_info(:poll, entity) do
        {:noreply, do_poll(entity)}
      end

      # ---

      # NOTE: this is the hass "state-machine"
      defp update_state(new_state, %{state: new_state} = entity) do
        entity
      end

      defp update_state(new_state, entity) do
        # IO.inspect(new_state, label: :state_changed)
        new_state = on_state_changed(entity, new_state)
        updated_entity = %Entity{entity | state: new_state}
        update_entity!(updated_entity)
        updated_entity
      end

      defp fire(entity, {signal, data}) do
        Phoenix.PubSub.broadcast(
          :event_pubsub,
          signal |> Atom.to_string(),
          {signal, %{from: entity, data: data}}
        )

        entity
      end
    end
  end
end
