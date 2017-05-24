# Nebulex

[![Build Status](https://travis-ci.org/cabol/nebulex.svg?branch=master)](https://travis-ci.org/cabol/nebulex)
[![Inline docs](http://inch-ci.org/github/cabol/nebulex.svg)](http://inch-ci.org/github/cabol/nebulex)
[![Coverage Status](https://coveralls.io/repos/github/cabol/nebulex/badge.svg?branch=master)](https://coveralls.io/github/cabol/nebulex?branch=master)

> **Local and Distributed Caching Tool for Elixir**

See the [getting started](https://hexdocs.pm/nebulex/getting-started.html) guide
and the [online documentation](https://hexdocs.pm/nebulex/Nebulex.html).

## Installation

Add `nebulex` to your list dependencies in `mix.exs`:

```elixir
def deps do
  [{:nebulex, github: "cabol/nebulex"}]
end
```

## Usage

1. Define a **Cache** module in your app:

```elixir
defmodule MyApp.LocalCache do
  use Nebulex.Cache, otp_app: :my_app
end
```

2. Start the **Cache** as part of your app supervision tree:

```elixir
defmodule MyApp do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(MyApp.LocalCache, [])
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

3. Configure `MyApp.LocalCache` in your `config.exs`:

```elixir
config :myapp, MyApp.LocalCache,
  adapter: Nebulex.Adapters.Local,
  n_shards: 2,
  gc_interval: 3600
```

 > **NOTE:** To learn more about the options, check the adapter documentation

4. Now you're ready to start using it!

```elixir
alias MyApp.LocalCache

LocalCache.set "foo", "bar", ttl: 2

"bar" = LocalCache.get "foo"

true = LocalCache.has_key? "foo"

%Nebulex.Object{key: "foo", value: "bar"} = LocalCache.get "foo", return: :object

:timer.sleep(2000)

nil = LocalCache.get "foo"

nil = "foo" |> LocalCache.set("bar", return: :key) |> LocalCache.delete
```

## Important links

 * [Documentation](https://hexdocs.pm/nebulex/Nebulex.html)
 * [Examples](https://github.com/cabol/nebulex_examples)
 * [Ecto Integration](https://github.com/cabol/nebulex_ecto)

## Testing

Testing by default spawns nodes internally for distributed tests.
To run tests that do not require clustering, exclude  the `clustered` tag:

```shell
$ mix test --exclude clustered
```

If you have issues running the clustered tests try running:

```shell
$ epmd -daemon
```

before running the tests.
