defmodule CoinPriceService.Service do
  alias __MODULE__.Worker
  alias CoinPriceService.{Monitor, Monitor.Repo, ClusterRegistry, ClusterServiceSupervisor}

  @spec start(keyword) :: {:ok, Monitor.t()} | :error
  def start(params) do
    with {:ok, new_monitor} <- Monitor.new(params),
         {:ok, monitor} <- Repo.upsert(new_monitor),
         child_spec <- worker_spec(monitor),
         {:ok, _} <- Horde.DynamicSupervisor.start_child(ClusterServiceSupervisor, child_spec) do
      {:ok, monitor}
    else
      _ -> :error
    end
  end

  defp worker_spec(%Monitor{id: monitor_id} = _monitor) do
    %{
      id: {Worker, monitor_id},
      start: {Worker, :start_link, [[monitor_id: monitor_id, name: via_tuple(monitor_id)]]},
      type: :worker,
      restart: :transient
    }
  end

  defp via_tuple(id) do
    {:via, Horde.Registry, {ClusterRegistry, {Monitor, id}}}
  end
end
