
# distributed algorithms, n.dulay, 10 jan 22
# simple client-server, v1

defmodule Server do

def start() do
  IO.puts "-> Server at #{Helper.node_string()}"
  # receive do
  # { :bind, client } -> next(client)
  # end
  next()
end # start

defp next() do
  receive do
    { client, :circle, radius } ->
      send client, { :result, 3.14159 * radius * radius }
    { client, :square, side } ->
      send client, { :result, side * side }
  end # receive
  next()
end # next

end # Server
