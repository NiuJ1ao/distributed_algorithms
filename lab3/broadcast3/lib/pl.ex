defmodule PL do

  @timeout 1000

  def start(beb) do
    IO.puts "--> PL of #{Helper.node_string()} started"

    receive do
      {:bind, pl_map} ->
        next beb, pl_map, MapSet.new, MapSet.new
    end

    # timer for stubberon link
    Process.send_after self(), :retransmit, @timeout
  end

  defp next beb, pl_map, sent, delivered do
    receive do
      # receive from same node
      {:pl_send, to, msg} ->
        # translate
        dest = Map.get(pl_map, to)

        send dest, {node(), msg}
        next beb, pl_map, MapSet.put(sent, {dest, msg}), delivered

      # receive from other node
      {from, msg} ->
        # eliminate duplicates
        if not MapSet.member?(delivered, msg) do
          send beb, {:pl_deliver, from, msg}
          next beb, pl_map, sent, MapSet.put(delivered, msg)
        end

      # retransmit forever
      :retransmit ->
        for {dest, msg} <- sent, do:
          send dest, {node(), msg}
        Process.send_after self(), :retransmit, @timeout
        next beb, pl_map, sent, delivered
    end
  end

end
