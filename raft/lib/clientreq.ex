
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule ClientReq do

# s = server process state (c.f. self/this)

# m = %{clientP: c.clientP, cid: cid, cmd: cmd}
def receive_request_from_client(s, m) do
  cond do
    s.role == :LEADER ->
      # append request to log and broadcast to followers
      s |> Debug.message("-creq", "Log size before append = #{Log.last_index(s)}")
      s = s |> Log.append_entry(%{term: s.curr_term, request: m})
            |> Monitor.send_msg({:CLIENT_REQUEST, s.server_num})
      s |> Debug.message("-creq", "Log size after append = #{Log.last_index(s)}")
        |> Debug.assert(Log.last_index(s) > 0, "ClientReq: entry is not appended")
      s |> AppendEntries.broadcast_append_entries_request_to_follower()
    s.role == :FOLLOWER and s.leaderP != nil ->
      send m.clientP, {:CLIENT_REPLY, m.cid, :NOT_LEADER, s.leaderP}
      s |> Debug.message("-creq", "Send leaderP to client")
    true ->
      s |> Debug.message("-creq", "Stale client requests due to no leader")
  end
end

end # Clientreq
