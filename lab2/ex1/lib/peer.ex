
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

defmodule Peer do

  # add your code here, start(), next() and any other functions
  def start do
    IO.puts "-> Peer at #{Helper.node_string()}"
    receive do
      {:bind, neighbours} ->
        IO.puts "-> Peer at #{Helper.node_string()} received neighbours"
        next_first(neighbours)
    end
  end

  defp next_first(neighbours) do
    receive do
      {:hello} ->
        Enum.each(neighbours, fn(x) ->
          send x, {:hello}
        end)
        next(neighbours, 1)
    end
  end

  defp next(neighbours, msg_count) do
    receive do
      {:hello} ->
        next(neighbours, msg_count+1)
      {:after} ->
        IO.puts "-> Peer at #{Helper.node_string()} (#{Helper.self_string()}) Messages seen = #{msg_count}"
    end
  end

end # Peer
