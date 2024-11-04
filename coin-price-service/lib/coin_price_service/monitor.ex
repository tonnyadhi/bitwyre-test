defmodule CoinPriceService.Monitor do
  alias __MODULE__
  alias CoinPriceService.Monitor.Price

  @pending_state :pending
  @processing_state :processing
  @ready_state :ready

  @type state :: :pending | :processing | :ready

  @type t :: %Monitor{
          id: String.t(),
          state: state,
          frequency: Integer.t(),
          from_time: DateTime.t(),
          until_time: DateTime.t(),
          prices: [Price.t()]
        }

  @enforce_keys [:id, :state, :frequency, :from_time, :until_time]

  @derive {Jason.Encoder, only: [:id, :state, :prices]}

  defstruct [
    :id,
    :state,
    :frequency,
    :from_time,
    :until_time,
    prices: []
  ]

  @spec new(keyword) :: {:ok, Monitor.t()} | :error
  def new(params) do
    with {:ok, period} <- Keyword.fetch(params, :period),
         valid_period when is_integer(period) <- period,
         {:ok, frequency} <- Keyword.fetch(params, :frequency),
         valid_frequency when is_integer(frequency) <- frequency,
         from_time <- Timex.now(),
         until_time <- Timex.shift(from_time, seconds: valid_period) do
      monitor = %Monitor{
        id: UUID.uuid1(),
        state: @pending_state,
        frequency: valid_frequency,
        from_time: from_time,
        until_time: until_time
      }

      {:ok, monitor}
    else
      _ -> :error
    end
  end

  @spec add_price(Monitor.t(), Price.t()) :: Monitor.t()
  def add_price(%Monitor{prices: old_prices} = monitor, %Price{} = new_price) do
    %{monitor | prices: [new_price | old_prices]}
  end

  @spec set_pending_state(Monitor.t()) :: Monitor.t()
  def set_pending_state(%Monitor{} = monitor), do: %{monitor | state: @pending_state}

  @spec set_processing_state(Monitor.t()) :: Monitor.t()
  def set_processing_state(%Monitor{} = monitor), do: %{monitor | state: @processing_state}

  @spec set_ready_state(Monitor.t()) :: Monitor.t()
  def set_ready_state(%Monitor{} = monitor), do: %{monitor | state: @ready_state}
end
