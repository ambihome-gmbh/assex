ExUnit.start()

defmodule TableHelper do
  @all_ids [
    "domain1.name1",
    "domain1.name2",
    "domain1.name3",
    "domain1.name4",
    "domain2.name5",
    "domain2.name6",
    "domain2.name7",
    "domain2.name8"
  ]

  def clear do
    Memento.Table.delete(Entity)
    Memento.Table.create!(Entity)
  end

  def init_simple(areas) do
    clear()

    @all_ids
    |> Enum.zip(areas)
    |> Enum.each(fn {id, area} ->
      [domain, name] = String.split(id, ".")
      Entity.Simple.new(name, domain, "area#{area}")
    end)

    :ok
  end

  def get_all_ids, do: @all_ids
end
