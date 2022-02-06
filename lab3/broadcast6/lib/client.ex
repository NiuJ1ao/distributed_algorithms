defmodule Client do

  def start(erb) do
    IO.puts "--> Client of #{Helper.node_string()} started"
    # wait to start braodcast
    receive do
      {:rb_deliver, _from, {:broadcast, counts, max_broadcasts, timeout}} ->
        Process.send_after(self(), :timeout, timeout)
        next erb, max_broadcasts, counts
    end
  end

  defp next erb, max_broadcasts, counts do
    receive do
      {:rb_deliver, from, _msg} ->
        {cin, cout} = Map.get(counts, from)
        next erb, max_broadcasts, Map.put(counts, from, {cin + 1, cout})
      :timeout ->
        IO.puts "#{Helper.node_string()}: #{inspect counts}"
    after
      0 ->
        if max_broadcasts > 0 do
          b = 10
          for _i <- 1..b, do:
            send erb, {:rb_broadcast, :rand.uniform(100_000_000_000)}

          next erb, max_broadcasts-b, Map.map(counts, fn {_k, {cin, cout}} -> {cin, cout + b} end)
        else
          next erb, max_broadcasts, counts
        end
    end
  end
end  # module Client
