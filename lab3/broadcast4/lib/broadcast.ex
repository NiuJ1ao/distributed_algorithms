
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
  peers = Enum.map(0..config.n_peers-1, fn(x) ->
    :'peer#{x}_#{config.node_suffix}'
  end)

  for p <- peers, do:
    Node.spawn(p, Peer, :start, [self(), peers])

  pl_map =
    for x <- 0..config.n_peers-1, into: Map.new do
      key = :'peer#{x}_#{config.node_suffix}'
      receive do {:pl, ^key, pl} -> {key, pl} end
    end
  IO.puts "#{inspect pl_map}"

  for {_x, pl} <- pl_map, do:
    send pl, {:bind, pl_map}

  counts =
    for p <- peers, into: Map.new do
      {p, {0, 0}}
    end

  for {_x, pl} <- pl_map, do:
    send pl, {node(), {:broadcast, counts, 1000, 3000}}

end # start/2

end # Broadcast
