defmodule FPL do
def start do
  receive do
  { :bind, c, pl } -> next c, pl, Map.new, [ ]
  end
end
defp next c, pl, pseqno, pending do
  receive do
    {:fpl_send, msg} ->
      seq_num = Map.get(pseqno, self(),  + 1
      pseqno = Map.put(pseqno, self(), seq_num)
      send pl, { :pl_send, {self(), msg, seq_num}}
      next <pseqno>
    { :pl_deliver, from, {:fpl_data, {sender, _, _}=frb_msg } ->
      pending = pending ++ [frb_msg]
      {pseqno, pending} = check_pending(c, sender, pseqno, pending)
      next <pseqno>, <pending>
      end # receive
  end

end

defp check_pending (c, sender, pseqno, pending) do
  case Enum.find(
    pending, fn {^sender, _, seq} -> seq == Map.get(pseqno, sender, 1) end)
  do
    {_, msg, seq} = data ->
      send c, {:fpl_deliver, msg}
      pseqno = Map.put(pseqno, sender, seq + 1)
      pending = List.delete(pending, data)
      {pseqno, pending} = check_pending <pseqno>, <pending>
    _otherwise -> {pseqno, pending}
  end # case
end
