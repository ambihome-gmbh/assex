defmodule Entity.SimpleTest do
  use ExUnit.Case

  setup do
    TableHelper.init_simple([1, 1, 2, 3, 4, 5, 3, 5])
    Phoenix.PubSub.subscribe(:event_pubsub, "state-changed")
  end

  test "new" do
    assert {:ok, _} = Entity.Simple.new("name", "domain", "area1")
    assert_receive {:state_change, %Entity{id: "domain.name", state: :off}}
    refute_receive {:state_change, _}
  end

  test "select" do
    assert ["domain1.name1", "domain1.name2", "domain1.name3", "domain1.name4"] ==
             select_ids({:==, :domain, "domain1"})
  end

  test "service calls" do
    Service.Call.call("domain1.name1", :turn_on)
    assert_state_equals("domain1.name1", :on)
    assert_receive {:state_change, %Entity{id: "domain1.name1", state: :on}}

    Service.Call.call("domain1.name1", :turn_off)
    assert_state_equals("domain1.name1", :off)
    assert_receive {:state_change, %Entity{id: "domain1.name1", state: :off}}

    refute_receive {:state_change, _}

    assert {:error, :unsupported_service} ==
             Service.Call.call("domain1.name1", :some_unsupported_service)
  end

  test "simple selector" do
    test_cast_by_selector({:==, :domain, "domain1"})
  end

  test "domain and area selector" do
    test_cast_by_selector({:and, {:==, :domain, "domain1"}, {:==, :area, "area1"}})
  end

  test "snested selector" do
    test_cast_by_selector({
      :and,
      {:or, {:==, :domain, "domain1"}, {:==, :domain, "domain2"}},
      {:or, {:==, :area, "area1"}, {:==, :area, "area3"}}
    })
  end

  # ---

  defp test_cast_by_selector(selector) do
    selected = select_ids(selector)

    assert :ok == Service.Call.call(selector, :turn_on)

    for entity_id <- selected do
      assert_receive {:state_change, %Entity{id: ^entity_id, state: :on}}
      assert_state_equals(entity_id, :on)
    end

    refute_receive {:state_change, _}

    for entity_id <- TableHelper.get_all_ids() -- selected do
      assert_state_equals(entity_id, :off)
    end
  end

  defp assert_state_equals(entity_id, expected_state) do
    assert %{state: ^expected_state} =
             Memento.transaction!(fn -> Memento.Query.read(Entity, entity_id) end)
  end

  defp select_ids(selector) do
    Service.Selector.select_entity_ids(selector)
  end
end
