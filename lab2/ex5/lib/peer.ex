
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

defmodule Peer do

  # add your code here, start(), next() and any other functions
  def start do
    num = :rand.uniform(10)
    IO.puts "-> Peer at #{Helper.node_string()} with random number #{num}"

    receive do
      {:bind, neighbours} ->
        IO.puts "-> Peer at #{Helper.node_string()} received neighbours #{inspect neighbours}"
        next_first(neighbours, num)
    end
  end

  defp next_first(neighbours, num) do
    receive do
      {:hello, parent, parent_pid} ->
        send parent_pid, {:child}
        Enum.each(neighbours, fn(x) ->
          send x, {:hello, Helper.node_string(), self()}
        end)
        next(neighbours, parent, parent_pid, 1, 0, num)
    end
  end

  defp next(neighbours, parent, parent_pid, msg_count, children, num) do
    receive do
      {:hello, _} ->
        next(neighbours, parent, parent_pid, msg_count+1, children, num)
      {:child} ->
        next(neighbours, parent, parent_pid, msg_count, children+1, num)
      {:after} ->
        result = summation(parent_pid, children, num)
        IO.puts "-> Peer #{Helper.node_string()} (#{Helper.self_string()}) Parent #{parent} Children = #{children} Sum = #{result}"
    end
  end

  defp summation(parent_pid, children, num) do
    if children == 0 do
      send parent_pid, {:sum, num}
      num
    else
      receive do
        {:sum, child_num} ->
          summation(parent_pid, children-1, num+child_num)
      end
    end
  end

end # Peer
