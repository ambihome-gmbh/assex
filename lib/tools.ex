defmodule Tools do
  # ------ lua

  def lua_table_to_map([]), do: %{}
  def lua_table_to_map(table), do: table |> Enum.map(&lua_get_item/1) |> Enum.into(%{})

  defp lua_get_item({k, v}) when is_list(v), do: {k, lua_table_to_map(v)}
  defp lua_get_item(item), do: item

  # ------ common

  def validate_maybe_atom(maybe_atom, msg, allowed \\ :any)

  def validate_maybe_atom(maybe_atom, msg, allowed) when is_atom(maybe_atom) do
    cond do
      allowed == :any -> {:ok, maybe_atom}
      maybe_atom in allowed -> {:ok, maybe_atom}
      true -> {:error, "#{msg}: #{inspect(maybe_atom)}"}
    end
  end

  def validate_maybe_atom(maybe_atom, msg, allowed) when is_binary(maybe_atom) do
    validate_maybe_atom(String.to_existing_atom(maybe_atom), msg, allowed)
  rescue
    ArgumentError -> {:error, "#{msg}: #{inspect(maybe_atom)}"}
  end

  def validate_maybe_atom(maybe_atom, msg, _allowed) do
    {:error, "#{msg}: #{inspect(maybe_atom)}"}
  end

  def validate(true, _error_msg), do: :ok
  def validate(false, error_msg), do: {:error, error_msg}
end
