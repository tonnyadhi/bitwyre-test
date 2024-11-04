defmodule CoinPriceService.Monitor.Repo do
@moduledoc """
  Dummy persistence layer using Elixir Nebulex
  Store data on distributed replicated cache node
"""
  use Nebulex.Cache,
    otp_app: :download_manager,
    adapter: Nebulex.Adapters.Replicated

  alias CoinPriceService.Monitor

  @spec fetch(String.t()) :: {:error, :not_found} | {:ok, any}
  def fetch(id) do
    case get(id) do
      nil ->
        {:error, :not_found}

      monitor ->
        {:ok, monitor}
    end
  end

  @spec upsert(Monitor.t()) :: {:ok, Monitor.t()}
  def upsert(%Monitor{id: id} = monitor) do
    :ok = put(id, monitor)

    {:ok, monitor}
  end

  @spec remove(Monitor.t()) :: {:ok, CoinPriceService.Monitor.t()}
  def remove(%Monitor{id: id} = monitor) do
    :ok = delete(id)

    {:ok, monitor}
  end
end
