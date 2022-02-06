
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

defmodule Peer do

  # add your code here, start(), next() and any other functions
  def start do
    IO.puts "--> Peer at #{Helper.node_string()}"
    receive do
      {:bind, ps} ->
        IO.puts "--> Peer at #{Helper.node_string()} is bound"
        counts =
          for p <- ps, into: Map.new()
            do {p, {0, 0}} end

        next ps, counts
    end
  end

  defp next ps, counts do
    receive do
      {:broadcast, max_broadcasts, timeout} ->
        IO.puts "--> Peer at #{Helper.node_string()} #{inspect counts}"
        Process.send_after(self(), :print, timeout)
        broadcast ps, max_broadcasts, counts
    end
  end

  defp broadcast ps, max_broadcasts, counts do
    b = 10
    Enum.each(1..b, fn(_x) ->
      for p <- ps, do:
        send(p, {:max_broadcasts, self()})
    end)

    deliver ps, max_broadcasts-b, Map.map(counts, fn {_k, {cin, cout}} -> {cin, cout + b} end)
  end

  defp deliver ps, max_broadcasts, counts do
    receive do
      {:max_broadcasts, from} ->
        # IO.puts "#{Helper.node_string()} received max_broadcasts from #{inspect(from)}"
        {cin, cout} = Map.get(counts, from)
        deliver ps, max_broadcasts, Map.put(counts, from, {cin + 1, cout})
      :print ->
        IO.puts "#{Helper.node_string()}: #{inspect counts}"
        Helper.node_exit
    after
      0 ->
        if max_broadcasts > 0 do
          broadcast ps, max_broadcasts, counts
        else
          deliver ps, max_broadcasts, counts
        end
    end
  end

end # Peer
