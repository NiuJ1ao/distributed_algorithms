
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
      {:hello, parent, parent_pid} ->
        send parent_pid, {:child}
        Enum.each(neighbours, fn(x) ->
          send x, {:hello, Helper.node_string(), self()}
        end)
        next(neighbours, parent, 1, 0)
    end
  end

  defp next(neighbours, parent, msg_count, children) do
    receive do
      {:hello, _} ->
        next(neighbours, parent, msg_count+1, children)
      {:child} ->
        next(neighbours, parent, msg_count, children+1)
      {:after} ->
        IO.puts "-> Peer #{Helper.node_string()} (#{Helper.self_string()}) Parent #{parent} Children = #{children}"
    end
  end

end # Peer
