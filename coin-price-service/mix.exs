defmodule BitcoinPriceService.MixProject do
  use Mix.Project

  def project do
    [
      app: :coin_price_service,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CoinPriceService.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8"},
      {:uuid, "~> 1.1"},
      {:nebulex, "~> 2.3"},
      {:timex, "~> 3.7"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.3"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
