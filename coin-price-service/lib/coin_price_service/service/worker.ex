defmodule CoinPriceService.Service.Worker do
  @moduledoc """
  Actual worker to demonstrate that the cluster work
  """

  use GenServer
  require Logger

  alias CoinPriceService.{Monitor, Monitor.Price, Monitor.Repo}

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    monitor_id = Keyword.fetch!(opts, :monitor_id)

    GenServer.start_link(__MODULE__, monitor_id, name: name)
  end

  @impl true
  def init(monitor_id) do
    {:ok, monitor_id, {:continue, :start}}
  end

  @impl true
  def handle_continue(:start, monitor_id) do
    {:ok, persisted_monitor} = Repo.fetch(monitor_id)

    {:ok, updated_monitor} =
      persisted_monitor
      |> Monitor.set_pending_state()
      |> Repo.upsert()

    schedule_process_loop(updated_monitor)

    log("start: #{inspect(updated_monitor)}")

    {:noreply, updated_monitor}
  end

  @impl true
  def handle_info(:process, monitor) do
    new_price = fetch_price()
    {:ok, frequency} = Map.fetch(monitor, :frequency)
    {:ok, from_time} = Map.fetch(monitor, :from_time)
    {:ok, until_time} = Map.fetch(monitor, :until_time)
    monitoring_interval = Timex.Interval.new(from: from_time, until: until_time)
    next_time = Timex.shift(Timex.now(), seconds: frequency)

    {:ok, updated_monitor} =
      monitor
      |> Monitor.set_processing_state()
      |> Monitor.add_price(new_price)
      |> Repo.upsert()

    if next_time in monitoring_interval do
      schedule(:process, frequency)
    else
      schedule(:ready, 0)
    end

    log("process: #{inspect(updated_monitor)}")

    {:noreply, updated_monitor}
  end

  @impl true
  def handle_info(:ready, monitor) do
    {:ok, updated_monitor} =
      monitor
      |> Monitor.set_ready_state()
      |> Repo.upsert()

    log("ready: #{inspect(updated_monitor)}")

    {:stop, :normal, updated_monitor}
  end

  defp schedule_process_loop(monitor) do
    {:ok, from_time} = Map.fetch(monitor, :from_time)
    {:ok, until_time} = Map.fetch(monitor, :until_time)
    monitoring_interval = Timex.Interval.new(from: from_time, until: until_time)
    current_time = Timex.now()
    next_time = calculate_next_wakup_time(monitor, current_time)

    cond do
      Timex.before?(current_time, from_time) ->
        schedule_timeout = Timex.diff(from_time, current_time, :seconds)
        schedule(:process, schedule_timeout)

      next_time in monitoring_interval ->
        next_current_diff = Timex.diff(next_time, current_time, :seconds)
        schedule_timeout = if next_current_diff > 0, do: next_current_diff, else: 0
        schedule(:process, schedule_timeout)

      true ->
        schedule(:ready, 0)
    end
  end

  defp calculate_next_wakup_time(monitor, current_time) do
    {:ok, frequency} = Map.fetch(monitor, :frequency)
    {:ok, prices} = Map.fetch(monitor, :prices)
    last_price = List.first(prices)
    last_price_time = if last_price, do: Map.get(last_price, :time)

    next_time =
      if last_price_time do
        Timex.shift(last_price_time, seconds: frequency)
      else
        current_time
      end

    next_time
  end

  defp schedule(action, timeout_in_seconds) do
    Process.send_after(self(), action, :timer.seconds(timeout_in_seconds))
  end

  # Stub Dummy Monitor
  defp fetch_price do
    {:ok, price} = Price.new(time: Timex.now(), amount: :rand.uniform(1000))

    price
  end

  defp log(text) do
    Logger.info("----[#{node()}]----[#{inspect(self())}]---#{text}")
  end
end
