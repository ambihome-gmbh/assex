defmodule Assex do
  @separator "."
  @replacement "_"
  @allowed_chars [?0..?9, ?a..?x, ?A..?Z, to_charlist(@separator)]
                 |> Enum.map(&Enum.to_list/1)
                 |> List.flatten()

  def get_unique_id(tab, parts) do
    suggested_id =
      parts
      |> Enum.map_join(@separator, &String.replace(&1, @separator, @replacement))
      |> String.normalize(:nfkc)
      |> String.to_charlist()
      |> Enum.map(&if &1 in @allowed_chars, do: &1, else: to_charlist(@replacement))
      |> List.to_string()

    get_unique_id_(tab, suggested_id)
  end

  defp get_unique_id_(tab, suggested_id, index \\ 0) do
    suffix = if index != 0, do: "#{@replacement}#{index}", else: ""
    id_attempt = suggested_id <> suffix

    if Memento.transaction!(fn -> Memento.Query.read(tab, id_attempt) end) do
      get_unique_id_(tab, suggested_id, index + 1)
    else
      id_attempt
    end
  end
end
