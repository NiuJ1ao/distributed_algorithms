defmodule BEB do
  def start(processes) do
    IO.puts "--> BEB of #{Helper.node_string()} started"
    receive do
      {:bind, pl, erb} -> next processes, pl, erb
    end
  end

  defp next processes, pl, erb do
    receive do
      {:beb_broadcast, msg} ->
        for dest <- processes, do:
          send pl, {:pl_send, dest, msg}
      {:pl_deliver, from, msg} ->
        send erb, {:beb_deliver, from, msg}
    end
    next processes, pl, erb
  end
end
