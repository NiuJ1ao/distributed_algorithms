
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
  client = Node.spawn(:'clientserver_#{config.node_suffix}', Client, :start, [])
  send server, { :bind, client }
  send client, { :bind, server }
end # start

defp start(_,      :cluster_wait), do: :skip
defp start(config, :cluster_start) do
  IO.puts "-> ClientServer at #{Helper.node_string()}"
  server = Node.spawn(:'server_#{config.node_suffix}', Server, :start, [])
  client = Node.spawn(:'client_#{config.node_suffix}', Client, :start, [])
  send server, { :bind, client }
  send client, { :bind, server }
end # start

end # ClientServer

