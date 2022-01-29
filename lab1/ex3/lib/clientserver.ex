
# distributed algorithms, n.dulay, 10 jan 22
# simple client-server, v1

defmodule ClientServer do

def start do
  config = Helper.node_init()
  start(config, config.start_function)
end # start

defp start(config, :single_start) do
  IO.puts "-> ClientServer at #{Helper.node_string()}"
  server = Node.spawn(:'clientserver_#{config.node_suffix}', Server, :start, [])
  Process.sleep(10)
  Enum.each(1..config.clients, fn(_x) ->
    client = Node.spawn(:'clientserver_#{config.node_suffix}', Client, :start, [])
    send client, { :bind, server }
  end)
end # start

defp start(_,      :cluster_wait), do: :skip
defp start(config, :cluster_start) do
  IO.puts "-> ClientServer at #{Helper.node_string()}"
  server = Node.spawn(:'server_#{config.node_suffix}', Server, :start, [])
  Process.sleep(10)
  Enum.each(1..config.clients, fn(x) ->
    client = Node.spawn(:'client#{x}_#{config.node_suffix}', Client, :start, [])
    send client, { :bind, server }
  end)
  #   client = Node.spawn(:'client#{n}_#{config.node_suffix}', Client, :start, [])
  #   # send server, { :bind, client }
  #   send client, { :bind, server }
end # start

end # ClientServer
