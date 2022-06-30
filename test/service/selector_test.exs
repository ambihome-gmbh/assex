defmodule Service.SelectorTest do
  use ExUnit.Case

  test "decoder" do
    assert {:error, "operator not allowed: 1"} ==
             Service.Selector.decode([1, 2, 3])

    assert {:error, "unexpected: 2"} ==
             Service.Selector.decode(["or", 2, 3])

    assert {:error, "(left) argument not allowed: :test"} ==
             Service.Selector.decode(["==", :test, "test"])

    assert {:error, "(left) argument not allowed: :test"} ==
             Service.Selector.decode(["==", "test", "test"])

    assert {:ok, {:==, :domain, "test"}} == Service.Selector.decode(["==", "domain", "test"])
    assert {:ok, {:==, :domain, "test"}} == Service.Selector.decode(["==", :domain, "test"])

    assert {:ok, {:!=, :area, "test"}} == Service.Selector.decode(["!=", "area", "test"])

    assert {:ok, {:or, {:!=, :area, "test"}, {:==, :domain, "test"}}} ==
             Service.Selector.decode(["or", ["!=", "area", "test"], ["==", "domain", "test"]])

    assert {:ok, {:or, {:!=, :area, "test"}, {:==, :domain, "test"}}} ==
             Service.Selector.decode({:or, {:!=, :area, "test"}, {:==, :domain, "test"}})
  end
end
