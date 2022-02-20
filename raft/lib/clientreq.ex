
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule ClientReq do

# s = server process state (c.f. self/this)

# m = %{clientP: c.clientP, cid: cid, cmd: cmd}
def receive_request_from_client(s, m) when s.role == :LEADER do
  # append request to log and broadcast to followers
  s |> Debug.message("-creq", "Log size before append = #{Log.last_index(s)}", 2)
  entry = %{term: s.curr_term, request: m}

  not_duplicate = not Enum.any?(s.log, fn({_i, e}) -> e == entry end)

  if not_duplicate do
    s = s |> Log.append_entry(entry)
          |> Monitor.send_msg({:CLIENT_REQUEST, s.server_num})
    s |> Debug.message("-creq", "Log size after append client request = #{Log.last_index(s)}")
      |> Debug.assert(Log.last_index(s) > 0, "ClientReq: server log is empty")
    s |> AppendEntries.broadcast_append_entries_request_to_follower()
  else
    s
  end
end

def receive_request_from_client(s, m) when s.role == :FOLLOWER and s.leaderP != nil do
  send m.clientP, {:CLIENT_REPLY, m.cid, :NOT_LEADER, s.leaderP}
  s |> Debug.message("-creq", "Send leaderP to client #{inspect m.cid}")
end

def receive_request_from_client(s, _m) do
  s |> Debug.message("-creq", "Reject client requests due to no leader")
end

end # Clientreq
