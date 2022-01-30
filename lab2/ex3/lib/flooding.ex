
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

# flood message through 1-hop (fully connected) network

defmodule Flooding do

def start do
  config = Helper.node_init()
  start(config, config.start_function)
end # start/0

defp start(_,      :cluster_wait), do: :skip
defp start(config, :cluster_start) do
  IO.puts "-> Flooding at #{Helper.node_string()}"

  # add your code here
  # create 10 peer processes
  peers = Enum.map(0..config.n_peers-1, fn(x) ->
      Node.spawn(:'peer#{x}_#{config.node_suffix}', Peer, :start, [])
    end)
  IO.puts "-> Flooding: #{inspect(peers)}, #{Enum.count(peers)}"

  # send neighbours to each peer
  bind(peers, 0, [1, 6]) # peer 0's neighbours are peers 1 and 6
  bind(peers, 1, [0, 2, 3])
  bind(peers, 2, [1, 3, 4])
  bind(peers, 3, [1, 2, 5])
  bind(peers, 4, [2])
  bind(peers, 5, [3])
  bind(peers, 6, [0, 7])
  bind(peers, 7, [6, 8, 9])
  bind(peers, 8, [7, 9])
  bind(peers, 9, [7, 8])

  # send hello to the first peer
  [first_peer|_] = peers
  send first_peer, {:hello, Helper.node_string()}

  # wait and print the result
  Process.sleep(1000)
  Enum.each(peers, fn(x) ->
    send x, {:after}
  end)
end # start/2

defp bind(peers, peer, neigh_indices) do
  root = Enum.at(peers, peer)
  neighbours = Enum.map(neigh_indices, fn(x) ->
    Enum.at(peers, x)
    end)
  send root, {:bind, neighbours}
end

end # Flooding
