defmodule Entity.File do
  use Entity, poll_interval: 100

  @impl Entity
  def do_poll(entity) do
    if File.exists?(entity.id) do
      update_state(:on, entity)
    else
      update_state(:off, entity)
    end
  end

  @impl Entity
  def on_state_changed(entity, :on) do
    fire(entity, {:trigger, :button_pressed})
    :on
  end

  def on_state_changed(entity, :off) do
    fire(entity, {:trigger, :button_released})
    :off
  end

  @impl Entity
  def service_call(:turn_on, _args, entity) do
    File.touch(entity.id)
    {:ok, entity}
  end

  def service_call(:turn_off, _args, entity) do
    File.rm(entity.id)
    {:ok, entity}
  end

  def service_call(_service, _args, _entity) do
    {:error, :unsupported_service}
  end
end
