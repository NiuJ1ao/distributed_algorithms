
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

defmodule Peer do

  # add your code here, start(), next() and any other functions
  def start do
    IO.puts "-> Peer at #{Helper.node_string()}"
    receive do
      {:bind, neighbours} ->
        IO.puts "-> Peer at #{Helper.node_string()} received neighbours #{inspect neighbours}"
        next_first(neighbours)
    end
  end

  defp next_first(neighbours) do
    receive do
      {:hello, parent} ->
        Enum.each(neighbours, fn(x) ->
          send x, {:hello, Helper.node_string()}
        end)
        next(neighbours, 1, parent)
    end
  end

  defp next(neighbours, msg_count, parent) do
    receive do
      {:hello, _} ->
        next(neighbours, msg_count+1, parent)
      {:after} ->
        IO.puts "-> Peer #{Helper.node_string()} (#{Helper.self_string()}) Parent #{parent} Messages seen = #{msg_count}"
    end
  end

end # Peer
