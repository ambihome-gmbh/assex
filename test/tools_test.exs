defmodule ToolsTest do
  use ExUnit.Case

  test "table to dict" do
    assert %{} ==
             Tools.lua_table_to_map([])

    assert %{1 => "A", 2 => "B", 3 => "C"} ==
             Tools.lua_table_to_map([{1, "A"}, {2, "B"}, {3, "C"}])

    assert %{"x" => 0, "y" => 0} ==
             Tools.lua_table_to_map([{"x", 0}, {"y", 0}])

    assert %{"a" => %{"aa" => %{"aaa" => 0}, "bb" => %{"bbb" => 0}}, "b" => 1, "c" => 2} ==
             Tools.lua_table_to_map([
               {"a", [{"aa", [{"aaa", 0}]}, {"bb", [{"bbb", 0}]}]},
               {"b", 1},
               {"c", 2}
             ])
  end
end
