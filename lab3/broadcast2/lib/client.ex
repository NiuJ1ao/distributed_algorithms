defmodule Client do

  def start do
    IO.puts "--> Client of #{Helper.node_string()} started"
    receive do
      {:bind, pl} ->
        next pl
    end
  end

  defp next pl do
    # wait to start braodcast
    receive do
      {:pl_deliver, _from, {:broadcast, peers, max_broadcasts, timeout}} ->
        Process.send_after(self(), :timeout, timeout)
        counts =
          for p <- peers, into: Map.new()
            do {p, {0, 0}} end
        broadcast pl, peers, max_broadcasts, counts
    end
  end

  def broadcast pl, peers, max_broadcasts, counts do
    receive do
      {:pl_deliver, from, _msg} ->
        {cin, cout} = Map.get(counts, from)
        broadcast pl, peers, max_broadcasts, Map.put(counts, from, {cin + 1, cout})

      :timeout ->
        IO.puts "#{Helper.node_string()}: #{inspect counts}"
        Helper.node_exit
    after
      0 ->
        if max_broadcasts > 0 do
          b = 10
          Enum.each(1..b, fn(_x) ->
            for p <- peers, do:
              send pl, {:pl_send, p, :rand.uniform(100_000_000_000)}
          end)
          broadcast pl, peers, max_broadcasts-b, Map.map(counts, fn {_k, {cin, cout}} -> {cin, cout + b} end)
        else
          broadcast pl, peers, max_broadcasts, counts
        end
    end
  end

end  # module Client
