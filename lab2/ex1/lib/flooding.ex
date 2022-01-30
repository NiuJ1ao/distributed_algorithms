
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
  IO.puts "-> Flooding: #{inspect(peers)}, #{Enum.count(peers)}}"

  # send neighbours to each peer
  Enum.each(peers, fn(x) ->
    send x, {:bind, peers}
  end)

  # send hello to the first peer
  [first_peer|_] = peers
  send first_peer, {:hello}

  # wait and print the result
  Process.sleep(1000)
  Enum.each(peers, fn(x) ->
    send x, {:after}
  end)
end # start/2

end # Flooding
