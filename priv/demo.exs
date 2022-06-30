defmodule Demo do
  alias Phoenix.PubSub

  def setup() do
    Memento.Table.delete(Entity)
    Memento.Table.create!(Entity)

    PubSub.subscribe(:event_pubsub, "state-changed")
  end

  def simple() do
    IO.puts("""
-----------------------------------------------------------------
This demo creates a File Enity.
Then uses its :turn_on service to create a file and deletes it using rm.

Watch out for the "domain.file" file appearing and disappearing.
-----------------------------------------------------------------
""")

    Entity.File.new("file", "domain", "dummy_area")

    for _ <- 1..10 do
      IO.puts("domain.file: turn_on")
      Service.Call.call("domain.file", :turn_on)
      :timer.sleep(1000)
      IO.puts("rm domain.file")
      File.rm("domain.file")
      :timer.sleep(1000)
    end
  end

  @logic_config [
    %{
      trigger: {:entities, ["domain.file1"]},
      function: {"file", "follow_state"},
      args: %{
        follow_me: {:entities, ["domain.file2"]}
      },
    }
  ]

  @logic_lua_modules %{
    "file" => """
    function follow_state(args)
      trigger = args["trigger"]
      target = args["args"]["follow_me"][1]

      if trigger.state == "off" then
        service = "turn_off"
      else
        service = "turn_on"
      end

      return {
        action="service_cast",
        service_cast={
          selector=target.id,
          service=service
        }
      }
    end
    """
  }

  def logic do
    IO.puts("""
    -----------------------------------------------------------------
    This demo creates two File Enities.
    It also creates a lua logic, that is triggered on a state-change of the "domain.file1" entity.
      When triggered it calls the `follow_state` which gets the other file entty as argument.
      The functions sets the state of this enity to the that of the triggering one.

    Watch out for the "domain.file1" and "domain.file2" files appearing and disappearing.
    -----------------------------------------------------------------
    """)

    _fw1 = Entity.File.new("file1", "domain", "dummy_area")
    _fw2 = Entity.File.new("file2", "domain", "dummy_area")

    Logic.new(@logic_config, @logic_lua_modules)

    for _ <- 1..10 do
      IO.puts("touch domain.file1")
      File.touch("domain.file1")
      :timer.sleep(1000)
      IO.puts("domain.file1: turn off")
      Service.Call.call("domain.file1", :turn_off)
      :timer.sleep(1000)
    end
  end

  def automation do
    IO.puts("""
    -----------------------------------------------------------------
    This demo creates a File Enity and a Automation.Simple.
      Then the file the enity watches is created.
      The File Enity fires a {:trigger, :button_pressed} event when the file is created.
      The simple automation reacts to this event by printing it out.

    Now the fun begins!
    You can create/delete or rename the "trigger.file" file yourself and see what happens!
    -----------------------------------------------------------------
    """)

    Automation.Simple.new(nil)

    Entity.File.new("file", "trigger", "dummy_area")

    File.touch("trigger.file")

    forever
  end

  defp forever do
    forever
  end
end

Demo.setup()

case System.argv() do
  ["logic"] -> Demo.logic
  ["automation"] -> Demo.automation
  ["simple"] -> Demo.simple
  _ -> Demo.simple
end
