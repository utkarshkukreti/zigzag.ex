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
end
