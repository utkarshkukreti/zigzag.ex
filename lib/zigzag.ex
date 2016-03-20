defmodule Zigzag do
  @doc """
  Applies `fun` to each item of `list` in parallel, running at most `limit`
  processes at any given time.

  ## Examples

      iex> Zigzag.each([1, 2, 3], 3, fn _ -> nil end)
      :ok
  """
  def each(list, limit, fun) do
    each(list, limit, fun, make_ref(), 0)
  end

  defp each([], _limit, _fun, _ref, 0), do: :ok
  defp each([h|t], limit, fun, ref, running) when running < limit do
    me = self
    spawn_link(fn ->
      fun.(h)
      send me, {ref, :cont}
    end)
    each(t, limit, fun, ref, running + 1)
  end
  defp each(list, limit, fun, ref, running) when is_list(list) do
    receive do
      {^ref, :cont} -> each(list, limit, fun, ref, running - 1)
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
    unordered_map(list, limit, fun, make_ref(), 0, [])
  end

  defp unordered_map([], _limit, _fun, _ref, 0, acc), do: acc
  defp unordered_map([h|t], limit, fun, ref, running, acc) when running < limit do
    me = self
    spawn_link(fn ->
      send me, {ref, :cont, fun.(h)}
    end)
    unordered_map(t, limit, fun, ref, running + 1, acc)
  end
  defp unordered_map(list, limit, fun, ref, running, acc) when is_list(list) do
    receive do
      {^ref, :cont, x} -> unordered_map(list, limit, fun, ref, running - 1, [x | acc])
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
    map(list, limit, fun, make_ref(), 0, 0, [])
  end

  defp map([], _limit, _fun, _ref, 0, _started, acc) do
    :lists.keysort(1, acc) |> Enum.map(fn {_i, x} -> x end)
  end
  defp map([h|t], limit, fun, ref, running, started, acc) when running < limit do
    me = self
    spawn_link(fn ->
      send me, {ref, :cont, started, fun.(h)}
    end)
    map(t, limit, fun, ref, running + 1, started + 1, acc)
  end
  defp map(list, limit, fun, ref, running, started, acc) when is_list(list) do
    receive do
      {^ref, :cont, i, x} ->
        map(list, limit, fun, ref, running - 1, started, [{i, x} | acc])
    end
  end
end
