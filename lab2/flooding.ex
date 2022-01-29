
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

end # start/2

end # Flooding

