defmodule Nebulex.TestCache do
  @moduledoc false

  defmodule Common do
    @moduledoc false

    defmacro __using__(_opts) do
      quote do
        def get_and_update_fun(nil), do: {nil, 1}
        def get_and_update_fun(current) when is_integer(current), do: {current, current * 2}

        def get_and_update_bad_fun(_), do: :other
      end
    end
  end

  defmodule Cache do
    @moduledoc false
    use Nebulex.Cache,
      otp_app: :nebulex,
      adapter: Nebulex.TestAdapter

    use Nebulex.TestCache.Common
  end

  ## Mocks

  defmodule AdapterMock do
    @moduledoc false
    @behaviour Nebulex.Adapter
    @behaviour Nebulex.Adapter.KV
    @behaviour Nebulex.Adapter.Queryable

    @impl true
    defmacro __before_compile__(_), do: :ok

    @impl true
    def init(opts) do
      child = {
        {Agent, System.unique_integer([:positive, :monotonic])},
        {Agent, :start_link, [fn -> :ok end, [name: opts[:child_name]]]},
        :permanent,
        5_000,
        :worker,
        [Agent]
      }

      {:ok, child, %{}}
    end

    @impl true
    def fetch(_, key, _) do
      if is_integer(key) do
        raise ArgumentError, "Error"
      else
        {:ok, :ok}
      end
    end

    @impl true
    def put(_, _, _, _, _, _) do
      :ok = Process.sleep(1000)

      {:ok, true}
    end

    @impl true
    def delete(_, _, _), do: :ok

    @impl true
    def take(_, _, _), do: {:ok, nil}

    @impl true
    def has_key?(_, _, _), do: {:ok, true}

    @impl true
    def ttl(_, _, _), do: {:ok, nil}

    @impl true
    def expire(_, _, _, _), do: {:ok, true}

    @impl true
    def touch(_, _, _), do: {:ok, true}

    @impl true
    def update_counter(_, _, _, _, _, _), do: {:ok, 1}

    @impl true
    def put_all(_, _, _, _, _) do
      {:ok, Process.exit(self(), :normal)}
    end

    @impl true
    def execute(_, %{op: :get_all}, _) do
      :ok = Process.sleep(1000)

      {:ok, []}
    end

    def execute(_, %{op: :count_all}, _) do
      _ = Process.exit(self(), :normal)

      {:ok, 0}
    end

    def execute(_, %{op: :delete_all}, _) do
      :ok = Process.sleep(2000)

      {:ok, 0}
    end

    @impl true
    def stream(_, _, _), do: {:ok, 1..10}
  end
end
