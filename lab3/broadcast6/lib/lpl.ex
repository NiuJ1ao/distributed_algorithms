defmodule LPL do
  def start(beb, reliability) do
    IO.puts "--> PL of #{Helper.node_string()} started"

    receive do
      {:bind, pl_map} ->
        next beb, pl_map, MapSet.new, MapSet.new, reliability
    end

    # timer for stubberon link
    Process.send_after(self(), :retransmit, 10)
  end

  defp next beb, pl_map, sent, delivered, reliability do
    is_send = :rand.uniform(99) < reliability
    receive do
      # receive from same node
      {:pl_send, to, msg} ->
        # translate
        dest = Map.get(pl_map, to)
        if is_send do
          send dest, {node(), msg}
          next beb, pl_map, MapSet.put(sent, {dest, msg}), delivered, reliability
        else
          next beb, pl_map, sent, delivered, reliability
        end

      # receive from other node
      {from, msg} ->
        # eliminate duplicates
        if not MapSet.member?(delivered, msg) do
          send beb, {:pl_deliver, from, msg}
          next beb, pl_map, sent, MapSet.put(delivered, msg), reliability
        end
        next beb, pl_map, sent, delivered, reliability

      # retransmit forever
      :retransmit ->
        IO.puts "retransmit"
        for {dest, msg} <- sent, do:
          send dest, {node(), msg}
        Process.send_after(self(), :retransmit, 10)
        next beb, pl_map, sent, delivered, reliability
    end
  end

end
