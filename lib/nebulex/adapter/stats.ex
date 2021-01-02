defmodule Nebulex.Adapter.Stats do
  @moduledoc """
  Specifies the stats API required from adapters.

  Each adapter is responsible for providing stats implementation. However,
  Nebulex provides a default implementation using [Erlang counters][counters],
  which is supported by the built-in adapters (with all callbacks overridable).

  [counters]: https://erlang.org/doc/man/counters.html

  See `Nebulex.Adapters.Local` for more information about how can be used from
  the adapter, and also [Nebulex Telemetry Guide][telemetry_guide] to learn how
  to use the Cache with Telemetry.

  [telemetry_guide]: http://hexdocs.pm/nebulex/telemetry.html
  """

  @doc """
  Returns `Nebulex.Stats.t()` with the current stats values.

  See `c:Nebulex.Cache.stats_info/0`.
  """
  @callback stats_info(Nebulex.Adapter.adapter_meta()) :: Nebulex.Stats.t()

  @doc """
  Returns the current value for the given `stat_name`.

  See `c:Nebulex.Cache.stats_info/1`.
  """
  @callback stats_info(
              Nebulex.Adapter.adapter_meta(),
              Nebulex.Stats.stat_name()
            ) :: non_neg_integer

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Nebulex.Adapter.Stats

      @impl true
      def stats_info(%{stats_counter: nil}), do: nil

      def stats_info(%{stats_counter: counter_ref}) do
        %Nebulex.Stats{
          hits: :counters.get(counter_ref, 1),
          misses: :counters.get(counter_ref, 2),
          writes: :counters.get(counter_ref, 3),
          evictions: :counters.get(counter_ref, 4),
          expirations: :counters.get(counter_ref, 5)
        }
      end

      @impl true
      def stats_info(adapter_meta, stat_field) do
        if info = stats_info(adapter_meta) do
          Map.fetch!(info, stat_field)
        end
      end

      defoverridable stats_info: 1, stats_info: 2
    end
  end

  import Nebulex.Helpers

  @doc """
  Initializes the Erlang's counter to be used by the adapter. See the module
  documentation for more information about the stats default implementation.

  Returns `nil` is the option `:stats` is set to `false` or it is not set at
  all; the stats will be skipped.

  ## Example

      Nebulex.Adapter.Stats.init(opts)

  > **NOTE:** This function is usually called by the adapter in case it uses
    the default implementation; the adapter should feed `Nebulex.Stats.t()`
    counters.

  See adapters documentation for more information about stats implementation.
  """
  @spec init(Keyword.t()) :: :counters.counters_ref() | nil
  def init(opts) do
    case get_option(opts, :stats, &is_boolean(&1), false) do
      true -> :counters.new(5, [:write_concurrency])
      false -> nil
    end
  end

  @doc """
  Increments the `counter`'s `stat_name` by the given `incr` value.

  ## Examples

      Nebulex.Adapter.Stats.incr(stats_counter, :hits)

      Nebulex.Adapter.Stats.incr(stats_counter, :writes, 10)

  > **NOTE:** This function is usually called by the adapter in case it uses
    the default implementation; the adapter should feed `Nebulex.Stats.t()`
    counters.

  See adapters documentation for more information about stats implementation.
  """
  @spec incr(:counters.counters_ref() | nil, Nebulex.Stats.stat_name(), integer) :: :ok
  def incr(counter, stat_name, incr \\ 1)

  def incr(nil, _stat, _incr), do: :ok
  def incr(ref, :hits, incr), do: :counters.add(ref, 1, incr)
  def incr(ref, :misses, incr), do: :counters.add(ref, 2, incr)
  def incr(ref, :writes, incr), do: :counters.add(ref, 3, incr)
  def incr(ref, :evictions, incr), do: :counters.add(ref, 4, incr)
  def incr(ref, :expirations, incr), do: :counters.add(ref, 5, incr)
end
