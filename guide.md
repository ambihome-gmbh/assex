# A little developers Guide

This is the POC for a smart-home hub. The implementation is inspired by https://www.home-assistant.io/. The software is not useful for anything at the moment but is and will be licensed under the same terms as https://www.home-assistant.io/ as it reuses it's domain model.

The purpose of a hub is to connect different real world services and devices and to make them work together.
Devices and services are abstracted in `Entities`.

For example you could write a `File`- Entity that watches a file and if that file gets deleted another entity reacts and switches on some light.

## applied Elixir modules

- https://hexdocs.pm/elixir/1.13/Registry.html
- https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html
- https://hexdocs.pm/memento/Memento.html
- https://hexdocs.pm/typed_struct/readme.html
- unimportant right now: https://github.com/rvirding/luerl

## Glossary

Understanding of these terms is needed to dive in:

- domain: right now this is just a string. `domain` is set as a field in entities, so entities can be selected by their `domain`. (examples: `light`, `button`, ...)
- area: right now this is just a string. `area` is set as a field in entities, so entities can be selected by their `area`.
- event-bus: a `Phoenix.PubSub` that is used by the parts of the system to communicate.

## Flow

A sequence of events starts with 
 - an Entity detects a state-change (see [@moduledoc in](lib/Entity.ex)) OR ...
 - a service call is executed (either received on the event-bus, eg from extern via MQTT or directly called from an Automation or Entity). (see [Service](lib/Service.ex), [Serivce.Call](lib/service/call.ex), [test "service calls" in](test/entity/simple_test.exs))
   - an Entity exececutes the call, its state may change
 - an `state-changed` event is sent
 - some other event may be sent
 - some Automation may react to the event

See tests and `priv/demo.exs` for some examples.

## Getting started

install Erlang+Elixir, see https://hexdocs.pm/nerves/installation.html#all-platforms

```
mix deps.get
mix run priv/demo.exs
```


