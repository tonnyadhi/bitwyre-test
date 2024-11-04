defmodule CoinPriceService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: CoinPriceService.ClusterSupervisor]]},
      {
        Horde.Registry,
        name: CoinPriceService.ClusterRegistry, keys: :unique, members: :auto
      },
      {
        Horde.DynamicSupervisor,
        name: CoinPriceService.ClusterServiceSupervisor, strategy: :one_for_one, members: :auto
      },
      CoinPriceService.Monitor.Repo,
      {
        Plug.Cowboy,
        scheme: :http,
        plug: CoinPriceService.Endpoint,
        options: [port: String.to_integer(System.get_env("PORT") || "4000")]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CoinPriceService.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end

  # Can also read this from conf files, but to keep it simple just hardcode it for now.
  # It is also possible to use different strategies for autodiscovery.
  # Following strategy works best for docker setup we using for this app.
  defp topologies do
    [
      coin_price_service: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [
            :"app@node1.dev",
            :"app@node2.dev",
            :"app@node3.dev"
          ]
        ]
      ]
    ]
  end
end
