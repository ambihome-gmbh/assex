defmodule Service.Call do
  use TypedStruct

  @type service :: atom
  @type args :: list

  typedstruct do
    field(:service, service(), enforce: true)
    field(:selector, Service.Selector.t())
    field(:args, args(), default: [])
    field(:method_, :call | :cast, default: :call)
  end

  @spec new(map) :: {:ok, t} | {:error, any}
  def new(%{service: service_, selector: selector_} = map) do
    args = Map.get(map, :args, [])

    with {:ok, service} <- Tools.validate_maybe_atom(service_, "unknown service"),
         :ok <- Tools.validate(is_list(args), "arguments not a list"),
         {:ok, selector} <- Service.Selector.decode(selector_) do
      {
        :ok,
        %__MODULE__{
          service: service,
          selector: selector,
          args: args
        }
      }
    end
  end

  def new(%{"service" => service, "selector" => selector} = map) do
    args = Map.get(map, "args", [])
    new(%{service: service, selector: selector, args: args})
  end

  @spec new(String.t()) :: {:ok, t} | {:error, any}
  def new(json) when is_binary(json) do
    # credo:disable-for-next-line
    json |> Jason.decode!(keys: :atoms) |> new
  end

  def new(selector, service, args \\ []) do
    new(%{selector: selector, service: service, args: args})
  end

  @spec call(t) :: :ok | {:error, any}
  def call(%__MODULE__{} = service_call) do
    results = service_call |> resolve_selector() |> Enum.map(&call_(&1))

    case Enum.uniq(results) do
      [single] -> single
      multiple -> {:error, multiple}
    end
  end

  def call(obj) do
    case Service.Call.new(obj) do
      {:ok, service_call} -> call(service_call)
      error -> error
    end
  end

  # TODO ??
  # lib/service/call.ex:64:no_return
  # Function call/2 has no local return.
  # ________________________________________________________________________________
  # lib/service/call.ex:64:no_return
  # Function call/3 has no local return.
  # ________________________________________________________________________________
  # lib/service/call.ex:65:call
  # The function call will not succeed.

  # Service.Call.call(%{:args => _, :selector => _, :service => _})

  # breaks the contract
  # (t()) :: :ok | {:error, any()}

  # ________________________________________________________________________________
  # done (warnings were emitted)
  # Halting VM with exit status 2
  def call(selector, service, args \\ []),
    do: call(%{selector: selector, service: service, args: args})

  defp call_(service_call) do
    case Registry.lookup(Registry.Entities, service_call.selector) do
      [{pid, _}] ->
        apply(GenServer, service_call.method_, [
          pid,
          {:service_call, service_call.service, service_call.args}
        ])

      _not_registered ->
        {:error, :entity_not_registered}
    end
  end

  @spec resolve_selector(t) :: [t]
  def resolve_selector(%__MODULE__{selector: selector} = service_call) do
    if is_binary(selector) do
      [service_call]
    else
      service_call.selector
      |> Service.Selector.select_entity_ids()
      |> Enum.map(&%{service_call | selector: &1, method_: :cast})
    end
  end
end
