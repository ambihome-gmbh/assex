defmodule Assex.Application do
  use Application

  @impl Application
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Entities},
      {Phoenix.PubSub, name: :event_pubsub}
    ]

    opts = [strategy: :one_for_one, name: Assex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
