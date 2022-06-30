defmodule Service.Selector do
  @type query_selector :: list(tuple) | tuple
  @type t :: query_selector | Entity.id()

  @spec select_entities(query_selector) :: [Entity.t()]
  def select_entities(selector) do
    Memento.transaction!(fn -> Memento.Query.select(Entity, selector) end)
  end

  @spec select_entity_ids(query_selector) :: [Entity.id()]
  def select_entity_ids(selector) do
    selector |> select_entities() |> Enum.map(& &1.id)
  end

  @spec decode(t | list) :: t
  def decode(selector) when is_binary(selector) do
    # NOTE: selector is an ID
    {:ok, selector}
  end

  def decode(selector) do
    {:ok, decode_(selector)}
  rescue
    error -> {:error, error.message}
  end

  @op_logic [:or, :and, :xor]
  @op_compare [:==, :===, :!=, :!==, :<, :<=, :>, :>=]
  @allowed_left_args [:domain, :area]

  # NOTE: memento allows to omit :and this is not implemented
  # ({:and, arg1, arg2} == [arg1, arg2])
  defp decode_([op_, left, right]) do
    case Tools.validate_maybe_atom(op_, "operator not allowed", @op_logic ++ @op_compare) do
      {:ok, op} -> decode_(op, left, right)
      {:error, msg} -> raise(ArgumentError, msg)
    end
  end

  defp decode_({op_, left, right}) do
    decode_([op_, left, right])
  end

  defp decode_(unexpected) do
    raise(ArgumentError, "unexpected: #{inspect(unexpected)}")
  end

  defp decode_(op, left, right) when op in @op_logic do
    {op, decode_(left), decode_(right)}
  end

  defp decode_(op, left_, right) when op in @op_compare do
    with {:ok, left} <-
           Tools.validate_maybe_atom(left_, "(left) argument not allowed", @allowed_left_args),
         :ok <- Tools.validate(is_binary(right), "(right) argument not allowed") do
      {op, left, right}
    else
      {:error, msg} -> raise(ArgumentError, msg)
    end
  end
end
