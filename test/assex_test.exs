defmodule AssexTest do
  use ExUnit.Case

  setup do
    TableHelper.clear()
    Phoenix.PubSub.subscribe(:event_pubsub, "state-changed")
  end

  test "unique id" do
    assert "domain.h_ll_o" = id = Assex.get_unique_id(Entity, ["domain", "héll*o"])
    Memento.transaction!(fn -> Memento.Query.write(%Entity{id: id, name: "name"}) end)
    assert "domain.h_ll_o_1" = id = Assex.get_unique_id(Entity, ["domain", "héll*o"])
    Memento.transaction!(fn -> Memento.Query.write(%Entity{id: id, name: "name"}) end)
    assert "domain.h_ll_o_2" = _id = Assex.get_unique_id(Entity, ["domain", "héll*o"])
  end
end
