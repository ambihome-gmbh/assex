defmodule Entity do
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
