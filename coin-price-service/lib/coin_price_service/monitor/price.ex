defmodule CoinPriceService.Monitor.Price do
  alias __MODULE__

  @type t :: %Price{
          time: DateTime.t(),
          amount: Integer.t()
        }

  @enforce_keys [:time, :amount]

  @derive Jason.Encoder

  defstruct [
    :time,
    :amount
  ]

  @spec new(keyword) :: {:ok, Price.t()} | :error
  # No validation!
  def new(params) do
    with {:ok, time} <- Keyword.fetch(params, :time),
         {:ok, amount} <- Keyword.fetch(params, :amount) do
      price = %Price{
        time: time,
        amount: amount
      }

      {:ok, price}
    else
      _ -> :error
    end
  end
end
