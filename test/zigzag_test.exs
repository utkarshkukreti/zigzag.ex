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

  test "unordered_map/3" do
    total = 11
    limit = 5
    {:ok, running} = Agent.start_link(fn -> 0 end)
    {time, list} = :timer.tc fn ->
      Zigzag.unordered_map Enum.to_list(1..total), limit, fn i ->
        Agent.update(running, &(&1 + 1))
        assert Agent.get(running, &(&1)) <= limit
        :timer.sleep((total - i + 1) * 10)
        Agent.update(running, &(&1 - 1))
        i * 2
      end
    end
    assert time < 20 * 10 * 1000
    assert Enum.sort(list) == [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]
  end

  test "map/3" do
    total = 11
    limit = 5
    {:ok, running} = Agent.start_link(fn -> 0 end)
    {time, list} = :timer.tc fn ->
      Zigzag.map Enum.to_list(1..total), limit, fn i ->
        Agent.update(running, &(&1 + 1))
        assert Agent.get(running, &(&1)) <= limit
        :timer.sleep((total - i + 1) * 10)
        Agent.update(running, &(&1 - 1))
        i * 2
      end
    end
    assert time < 20 * 10 * 1000
    assert list == [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]
  end
end
