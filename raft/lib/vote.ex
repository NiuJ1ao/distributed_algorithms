
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule Vote do

# s = server process state (c.f. self/this)

def send_vote_reply_to_candidate(s, candidateP, voteGranted) do
  msg = %{
    election: s.curr_election,
    voteGranted: voteGranted,
    voted_for: s.voted_for,
    voted_by: s.selfP
  }
  send candidateP, {:VOTE_REPLY, s.curr_term, msg}
  s |> Debug.message("+vrep", msg)
end

def receive_vote_reply_from_follower(s, mterm, m) do
  cond do
    mterm > s.curr_term and not m.voteGranted ->
      s |> Server.follower_if_higher(mterm)
    mterm == s.curr_term and s.role == :CANDIDATE and m.voteGranted ->
      s = s |> State.add_to_voted_by(m.voted_by)
      if State.vote_tally(s) > s.majority do
        # become leader
        s |> Debug.message("-vrep", "Become leader")
          |> Timer.cancel_election_timer()
          |> State.role(:LEADER)
          |> State.leaderP(s.selfP)
          |> State.init_next_index()  # reinitialize after election
          |> State.init_match_index()
          |> AppendEntries.broadcast_append_entries_request_from_leader()
      else
        s
      end
    true ->
      s |> Debug.message("-vrep", "#{inspect m} is ignored")
  end
end

def receive_vote_request_from_candidate(s, mterm, m) do
  cond do
    mterm > s.curr_term ->
      s |> Server.follower_if_higher(mterm)
        |> send_vote_reply_to_candidate(m.from, true)
    mterm == s.curr_term and s.voted_for != nil and (m.last_term > Log.last_term(s) or (m.last_term == Log.last_term(s) and m.last_index >= Log.last_index(s))) ->
      s |> State.voted_for(m.from)
        |> Timer.restart_election_timer()
        |> send_vote_reply_to_candidate(m.from, true)
    true ->
      s |> send_vote_reply_to_candidate(m.from, false)
  end
end

def receive_election_timeout(s) do
  if s.role == :FOLLOWER or s.role == :CANDIDATE do
    s |> State.inc_election()
      |> State.inc_term()               # increment current term
      |> State.role(:CANDIDATE)         # change to candidate
      |> State.voted_for(s.selfP)       # vote for self
      |> State.new_voted_by()
      |> State.add_to_voted_by(s.selfP)
      |> Timer.restart_election_timer() # set new timeout
      |> broadcast_vote_requests()
  else
    s
  end
end

defp broadcast_vote_requests(s) do
  for server <- s.servers, server != s.selfP, do:
      send server, {:VOTE_REQUEST, s.curr_term, %{
        from: s.selfP,
        last_term: Log.last_term(s),
        last_index: Log.last_index(s)
      }}
  s |> Debug.message("+vreq", "Broadcast vote requests")
end

end # Vote
