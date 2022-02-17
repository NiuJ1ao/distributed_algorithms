
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule ClientReq do

# s = server process state (c.f. self/this)

# m = %{clientP: c.clientP, cid: cid, cmd: cmd}
def receive_request_from_client(s, m) do
  cond do
    s.role == :LEADER ->
      s |> Log.append_entry(%{
        term: s.curr_term,
        request: m
      })
        |> Debug.message("-creq", "Log size after append = #{Log.last_index(s)}")
        |> AppendEntries.broadcast_append_entries_request_to_follower()
    s.role == :FOLLOWER and s.leaderP != nil ->
        send m.clientP, {:CLIENT_REPLY, m.cid, :NOT_LEADER, s.leaderP}
        s |> Debug.message("-creq", "Send leader to client")
    true ->
      s |> Debug.message("-creq", "Stale client requests since not leader or leaderP is nil")
  end
end

end # Clientreq
