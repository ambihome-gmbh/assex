defmodule Service.CallTest do
  use ExUnit.Case

  test "new" do
    assert {:ok, %Service.Call{args: [], selector: "entity-id", service: :service}} ==
             Service.Call.new(%{service: :service, selector: "entity-id", args: []})

    assert {:ok, %Service.Call{args: [], selector: "entity-id", service: :service}} ==
             Service.Call.new(%{service: "service", selector: "entity-id", args: []})
  end
end
