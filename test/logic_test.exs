defmodule LogicTest do
  use ExUnit.Case

  setup do
    TableHelper.init_simple([1, 1, 2, 3, 4, 5, 3, 5])
    Phoenix.PubSub.subscribe(:event_pubsub, "state-changed")
  end

  @config [
    %{
      trigger: {:entities, ["domain1.name1"]},
      args: %{
        foo: {:entities, ["domain1.name2", "domain1.name4"]},
        bar: {:entities, ["domain1.name3"]}
      },
      function: {"hello", "world"}
    },
    %{
      trigger: {:entities, ["domain1.name1", "domain1.name2"]},
      args: %{foo: {:entities, ["domain1.name3", "domain1.name4"]}},
      function: {"hello", "there"}
    },
    %{
      trigger: {:selector, [{:==, :domain, "domain1"}]},
      args: %{foo: {:selector, [{:==, :domain, "domain2"}]}},
      function: {"hello", "again"}
    }
  ]

  @lua_modules %{
    "hello" => """
    function world(args)
        return {action="write_entities", entities=args["args"]["foo"]}
    end
    function there(args)
        return {action="write_entities", entities=args["args"]["foo"]}
    end
    function again(args)
        return {action="write_entities", entities=args["args"]["foo"]}
    end
    """
  }

  test "logic config" do
    assert %{
             triggers: %{
               "domain1.name1" => [0, 1, 2],
               "domain1.name2" => [1, 2],
               "domain1.name3" => [2],
               "domain1.name4" => [2]
             },
             config: %{},
             vms: %{"hello" => _}
           } = Logic.load(@config, @lua_modules)
  end

  test "logic load args" do
    assert %{
             foo: [
               %{id: "domain1.name1"},
               %{id: "domain1.name2"}
             ]
           } = Logic.load_args(%{foo: {:entities, ["domain1.name1", "domain1.name2"]}})

    assert %{
             bar: [%{id: "domain1.name3"}],
             foo: [%{id: "domain1.name2"}, %{id: "domain1.name4"}]
           } =
             Logic.load_args(%{
               bar: {:entities, ["domain1.name3"]},
               foo: {:entities, ["domain1.name2", "domain1.name4"]}
             })

    assert %{
             foo: [
               %{id: "domain2.name5"},
               %{id: "domain2.name8"},
               %{id: "domain2.name6"},
               %{id: "domain2.name7"}
             ]
           } = Logic.load_args(%{foo: {:selector, [{:==, :domain, "domain2"}]}})
  end

  # test "lcall" do
  #   %{config: config, vms: vms} = Logic.load(@config, @lua_modules)

  #   assert [
  #            %{
  #              "action" => "write_entities",
  #              "entities" => %{
  #                1 => %{
  #                  "area" => "area1",
  #                  "domain" => "domain1",
  #                  "id" => "domain1.name2",
  #                  "name" => "name2",
  #                  "state" => "off"
  #                },
  #                2 => %{
  #                  "area" => "area3",
  #                  "domain" => "domain1",
  #                  "id" => "domain1.name4",
  #                  "name" => "name4",
  #                  "state" => "off"
  #                }
  #              }
  #            }
  #          ] == Logic.call(config[0], %Entity{id: "domain2.name5"}, vms)
  # end
end
