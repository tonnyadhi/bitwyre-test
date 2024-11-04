# CoinPriceService

This is a demo service to show Horde and Libcluster.
Even the distributed / replicated data is not working on Nebulex to distributed the monitoring task.


## How to start

```bash
docker network create cluster-net
docker-compose build
docker-compose up
```


### Usage Example

```bash
# Start monitoring task:
curl -X POST http://localhost:4001/monitor -H 'Content-Type: application/json' -d '{"period":10,"frequency":2}'

# Response:
{"id":"a713a07a-d5b1-11ec-af3a-0242ac130002"}%

# Get results or check status:
curl http://localhost:4001/monitor/a713a07a-d5b1-11ec-af3a-0242ac130002
```
