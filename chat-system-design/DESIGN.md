# High Availability Chat Server with Elixir

## Assumptions

Judging from the requirement given on [here]([here](https://github.com/bitwyre/interview-question/blob/main/README.md#2-chat-application-design-a-chat-application)) on problem No.2 (Chat Application Design). These assumptions can be made :
- The chat server design to be high throughput and handle high RPS from (assumed) high number of users
- It should be made into clustered environment for High Availability, Reliability and also some of the features requirement
- There exist long term message storage to aggregate data or keep long term chat history. The period for storage is not given, assume as long as the user become the member of the system
- The application front end is a web based


## Tech Stack Selection

The tech stack selection that i being used on the system are Elixir based. The tech stack selection is based on these reasoning :
- Exploit Erlang/OTP BEAM VM easeness on constructing Distributed Nodes. This will a little bit lift the engineering burden on thinking of Distributed Concurrency & Distributed Locking
- Exploiting Elixir Libcluster to formed distributed nodes on various infrastructure orchestration, including k8s
- Small process footprint within Erlang VM. 3kB when bootstrapping a process structure
- Each of BEAM process is fully isolated, immutable on their data and only communicate via Message Passing
- CRDT Support (Conflict Free Replicated Data Type) support with Riak or Elixir own library for Delta Type CRDT
- Distributed supervisor is supported for supervise hundreds / thousands of processes on multiple nodes. Enabling handover of chat and chat room if a node goes down
- Beauty of Functional Programming (Debatable :P)

Some cons that might exist :
- I'm still not thinking on how Riak traffic for CRDT messaging. How much capacity that will become overhead because of this traffic
- Multi k8s cluster forming with libcluster and its topology. Are there any hardships on forming the cluster
- BEAM VM overhead perhaps compared to compiled solution using C/C++/Go, buat AFAIK BEAM vm quite lightweight


## Design Rationale & Components

Design rationale and system components are as follow :
- A distributed supervisor must be started within the cluster. Alongside that, this cluster also will carry a distributed process registry. This can be done via [Horde](https://github.com/derekkraan/horde)
- Horde states are replicated using CRDT.
- A local Chat room / Chat server supervisor will be started in each node. This local Elixir Gen Server process will be managed by Horde
- Each chat supervisor will supervise many of local Chat Room process. 
- Each chat room process will registered themselves with Horde Process Registry (in order to get local and global view of the system)
- Each of the chat room will use their append only database to Riak and replicated via Riak CRDT
- A Handover process is implemented within Horde Supervisor to re-route chat if a Node goes down.
- Riak stream its data to Kafka/Redpanda for long term storage
- Redpanda used its Cloud Object storage capability to shard data that rarely accessed (ex: chat archive)
  
### Design Whiteboard

Available on [Excalidraw](https://excalidraw.com/#room=bbc919e7f802e3f4f35a,PedEC4D15VtNgRvqlhvpEg)