
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule ClientReq do

# s = server process state (c.f. self/this)

def receive_request_from_client(s, m) do
  # if s.role == :LEADER do
  #   s |> Log.append(%{
  #     term: s.curr_term,
  #     request: m
  #   })
  #     |> AppendEntries.broadcast_append_entries_request_to_follower()
  # else
  #   s
  # end
  s
end

end # Clientreq
