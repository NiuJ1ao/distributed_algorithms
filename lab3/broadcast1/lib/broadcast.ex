
# distributed algorithms, n.dulay, 10 jan 22
# lab3 - broadcast algorithms

# v1 - elixir broadcast

defmodule Broadcast do

def start do
  config = Helper.node_init()
  start(config, config.start_function)
end # start/0

defp start(_,      :cluster_wait), do: :skip
defp start(config, :cluster_start) do
  IO.puts "--> Broadcast at #{Helper.node_string()}"

  # add your code here
  # create and bind
  peers = Enum.map(0..4, fn(x) ->
    Node.spawn(:'peer#{x}_#{config.node_suffix}', Peer, :start, [])
  end)

  for p <- peers, do:
    send p, {:bind, peers}

  for p <- peers, do:
    send p, {:broadcast, 1000, 3000}

end # start/2

end # Broadcast
