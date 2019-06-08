defmodule CockpitNodeTest do
  use ExUnit.Case
  doctest CockpitNode

  test "greets the world" do
    assert CockpitNode.hello() == :world
  end
end
