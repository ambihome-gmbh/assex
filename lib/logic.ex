defmodule Logic do
  @moduledoc """
  Ignore for now.
  """
  use GenServer

  def new(config, modules) do
    GenServer.start_link(__MODULE__, load(config, modules), name: __MODULE__)
  end

  @impl GenServer
  def init(config) do
    Phoenix.PubSub.subscribe(:event_pubsub, "state-changed")
    {:ok, config}
  end

  @impl GenServer
  def handle_info({:state_change, %Entity{} = entity}, state) do
    state.triggers
    |> Map.get(entity.id, [])
    |> Enum.each(&call(state.config[&1], entity, state.vms))

    {:noreply, state}
  end

  # ------------------------------------------------

  def load(config, modules) do
    # TODO check if all entities configured exist!
    config = config |> Enum.with_index(fn e, i -> {i, e} end) |> Enum.into(%{})

    %{
      triggers: get_trigger_map(config),
      vms: load_modules(modules),
      config: config
    }
  end

  def load_modules(modules) do
    modules
    |> Enum.map(fn {name, code} -> {name, load_module(code)} end)
    |> Enum.into(%{})
  end

  def call(config_item, triggering_entity, vms) do
    args = %{
      args: load_args(config_item.args),
      trigger: triggering_entity
    }

    {m, f} = config_item.function

    # TODO handle multiple results, handle write_entity action
    case call_function(f, args, vms[m]) do
      [%{"action" => "service_cast", "service_cast" => service_cast}] ->
        Service.Call.call(service_cast)

      _result ->
        raise("not implemented")
    end
  end

  # ---
  # TODO errorcheck
  defp load_module(code) do
    {_, vm} = :luerl.do(code, :luerl.init())
    vm
  end

  # TODO errorcheck
  defp call_function(name, args, vm) do
    {result, _} = :luerl.call_function([name], [args], vm)
    Enum.map(result, &Tools.lua_table_to_map/1)
  end

  def load_args(args) do
    args
    |> Enum.map(fn {name, selector} -> {name, load_arg(selector)} end)
    |> Enum.into(%{})
  end

  defp load_arg(selector) do
    selector |> load_arg_() |> Enum.map(&Map.drop(&1, [:__meta__, :__struct__]))
  end

  defp load_arg_({:entities, entities}) do
    Memento.transaction!(fn ->
      Enum.map(entities, fn e -> Memento.Query.read(Entity, e) end)
    end)
  end

  defp load_arg_({:selector, selector}) do
    Service.Selector.select_entities(selector)
  end

  defp get_trigger_map(config) do
    config
    |> Enum.map(fn {index, item} -> {resolve(item.trigger), index} end)
    |> Enum.reduce(%{}, fn {triggers, index}, acc -> reduce_item(triggers, index, acc) end)
  end

  defp resolve({:entities, entities}), do: entities

  defp resolve({:selector, selector}),
    do: selector |> Service.Selector.select_entities() |> Enum.map(& &1.id)

  defp setdefault(m, k, v), do: Map.update(m, k, [v], fn old -> old ++ [v] end)

  defp reduce_item(triggers, index, acc) do
    Enum.reduce(triggers, acc, fn trigger, acc -> setdefault(acc, trigger, index) end)
  end
end
