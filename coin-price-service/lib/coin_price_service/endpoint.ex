defmodule CoinPriceService.Endpoint do
  use Plug.Router

  alias CoinPriceService.{Monitor, Service}

  plug(Plug.Logger)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/monitor/:id" do
    with {:ok, monitor} <- Monitor.Repo.fetch(id),
         {:ok, resp} <- Jason.encode(monitor) do
      send_resp(conn, 200, resp)
    else
      _ ->
        {:ok, resp} = Jason.encode(%{error: "Something went wrong"})
        send_resp(conn, 500, resp)
    end
  end

  # Accepts POST params in JSON
  # Example: `{"period":10,"frequency":2}`
  # Make sure params are integers, not strings.
  # It doesn't normalize input and have only basic validation
  post "/monitor" do
    with %{"period" => period, "frequency" => frequency} <- conn.body_params,
         {:ok, %Monitor{id: id}} <- Service.start(period: period, frequency: frequency),
         {:ok, resp} = Jason.encode(%{id: id}) do
      send_resp(conn, 200, resp)
    else
      _ ->
        {:ok, resp} = Jason.encode(%{error: "Something went wrong"})
        send_resp(conn, 500, resp)
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
