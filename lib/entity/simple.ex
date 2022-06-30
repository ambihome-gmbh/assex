defmodule Entity.Simple do
  use Entity

  @impl Entity
  # @spec service_call(Service.id(), list, Entity.t()) :: {:error, _} | {:ok, Entity.t()}
  # @spec service_call(any, any, any) :: {:error, _} | {:ok, any}
  def service_call(:turn_on, _args, entity) do
    {:ok, update_state(:on, entity)}
  end

  def service_call(:turn_off, _args, entity) do
    {:ok, update_state(:off, entity)}
  end

  def service_call(_service, _args, _entity) do
    {:error, :unsupported_service}
  end
end
