defmodule ZigzagTest do
  use ExUnit.Case
  doctest Zigzag

  test "each/3" do
    total = 11
    limit = 5
    {:ok, ran} = Agent.start_link(fn -> 0 end)
    {:ok, running} = Agent.start_link(fn -> 0 end)
    {time, :ok} = :timer.tc fn ->
      Zigzag.each Enum.to_list(1..total), limit, fn i ->
        Agent.update(running, &(&1 + 1))
        assert Agent.get(running, &(&1)) <= limit
        :timer.sleep(i * 10)
        Agent.update(ran, &(&1 + 1))
        Agent.update(running, &(&1 - 1))
      end
    end
    assert time < 20 * 10 * 1000
    assert Agent.get(ran, &(&1)) == total
  end
end
