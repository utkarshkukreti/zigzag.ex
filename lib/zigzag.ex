defmodule Zigzag do
  @doc """
  Applies `fun` to each item of `list` in parallel, running at most `limit`
  processes at any given time.

  ## Examples

      iex> Zigzag.each([1, 2, 3], 3, fn _ -> nil end)
      :ok
  """
  def each(list, limit, fun) do
    each(list, limit, fun, 0)
  end

  defp each([], _limit, _fun, 0), do: :ok
  defp each([h|t], limit, fun, running) when running < limit do
    me = self
    spawn_link(fn ->
      fun.(h)
      send me, :cont
    end)
    each(t, limit, fun, running + 1)
  end
  defp each(list, limit, fun, running) when is_list(list) do
    receive do
      :cont -> each(list, limit, fun, running - 1)
    end
  end

  @doc """
  Applies `fun` to each item of `list` in parallel, returning the return values
  of `fun` in a list in an unspecified order, running at most `limit` processes
  at any given time.

  ## Examples

      iex> Zigzag.unordered_map([1, 2, 3], 3, fn x -> x * 2 end) |> Enum.sort
      [2, 4, 6]
  """
  def unordered_map(list, limit, fun) do
    unordered_map(list, limit, fun, 0, [])
  end

  defp unordered_map([], _limit, _fun, 0, acc), do: acc
  defp unordered_map([h|t], limit, fun, running, acc) when running < limit do
    me = self
    spawn_link(fn ->
      send me, {:cont, fun.(h)}
    end)
    unordered_map(t, limit, fun, running + 1, acc)
  end
  defp unordered_map(list, limit, fun, running, acc) when is_list(list) do
    receive do
      {:cont, x} -> unordered_map(list, limit, fun, running - 1, [x | acc])
    end
  end

  @doc """
  Applies `fun` to each item of `list` in parallel, returning the return values
  of `fun` in a list in the same order as `list`, running at most `limit`
  processes at any given time.

  ## Examples

      iex> Zigzag.map([1, 2, 3], 3, fn x -> x * 2 end)
      [2, 4, 6]
  """
  def map(list, limit, fun) do
    map(list, limit, fun, 0, 0, [])
  end

  defp map([], _limit, _fun, 0, _started, acc) do
    :lists.keysort(1, acc) |> Enum.map(fn {_i, x} -> x end)
  end
  defp map([h|t], limit, fun, running, started, acc) when running < limit do
    me = self
    spawn_link(fn ->
      send me, {:cont, started, fun.(h)}
    end)
    map(t, limit, fun, running + 1, started + 1, acc)
  end
  defp map(list, limit, fun, running, started, acc) when is_list(list) do
    receive do
      {:cont, i, x} ->
        map(list, limit, fun, running - 1, started, [{i, x} | acc])
    end
  end
end
