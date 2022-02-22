
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

# Yuchen Niu (yn621) and Zian Wang (zw4821)

defmodule Vote do

# s = server process state (c.f. self/this)

# Bug: possible two leader: 3 servers. Two server broadcast VoteReq at the same time. The third server first stepdown and erase the voted record. When it receive another VoteReq, it will vote for another server -solved.

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

# ________________________________________________________________________ Follower >> Candidate
def receive_vote_reply_from_follower(s, mterm, m) when m.election > s.curr_election do
  s |> State.curr_election(m.election)
    |> Server.follower_if_higher(mterm)
end # receive_vote_reply_from_follower

def receive_vote_reply_from_follower(s, _mterm, m) when m.election == s.curr_election and s.role == :CANDIDATE and m.voteGranted and (m.voted_for == nil or m.voted_for == s.selfP) do
  s = s |> State.add_to_voted_by(m.voted_by)
  if State.vote_tally(s) >= s.majority do
    # become leader
    s |> Timer.cancel_election_timer()
      |> State.role(:LEADER)
      |> Debug.message("!inf", "Become leader")
      |> State.leaderP(s.selfP)
      |> State.init_next_index()  # reinitialize after election
      |> State.init_match_index()
      |> AppendEntries.broadcast_append_entries_request_to_follower()
  else
    s
  end
end # receive_vote_reply_from_follower

def receive_vote_reply_from_follower(s, _mterm, m) do
  s |> Debug.message("-vrep", "Ignore vote #{inspect m}")
end # receive_vote_reply_from_follower

# ________________________________________________________________________  Candidate >> Follower
defp is_valid_vote(s, m) do
  (s.voted_for == nil or s.voted_for == m.candidateP) and (m.last_term > Log.last_term(s) or (m.last_term == Log.last_term(s) and m.last_index >= Log.last_index(s)))
end

def receive_vote_request_from_candidate(s, mterm, m) when m.election > s.curr_election do
  s |> Server.follower_if_higher(mterm)
    |> State.curr_election(m.election)
    |> State.voted_for(m.candidateP)
    |> send_vote_reply_to_candidate(m.candidateP, true)
end # receive_vote_request_from_candidate

def receive_vote_request_from_candidate(s, _mterm, m) do
  if m.election == s.curr_election and is_valid_vote(s, m) do
    s |> State.voted_for(m.candidateP)
      |> Timer.restart_election_timer()
      |> send_vote_reply_to_candidate(m.candidateP, true)
  else
    s |> Debug.message("-vreq", "Reject to vote")
      |> Timer.restart_election_timer()
      |> send_vote_reply_to_candidate(m.candidateP, false)
  end
end # receive_vote_request_from_candidate

# ________________________________________________________________________  Self >> Self
def receive_election_timeout(s) when s.role == :FOLLOWER or s.role == :CANDIDATE do
  s |> State.inc_election()
    |> State.inc_term()               # increment current term
    |> Timer.restart_election_timer() # set new timeout
    |> State.role(:CANDIDATE)         # change to candidate
    |> State.leaderP(nil)
    |> State.voted_for(s.selfP)       # vote for self
    |> State.new_voted_by()
    |> State.add_to_voted_by(s.selfP)
    |> broadcast_vote_requests()
end # receive_election_timeout

def receive_election_timeout(s) do
  s
end # receive_election_timeout

defp broadcast_vote_requests(s) do
  for server <- s.servers, server != s.selfP, do:
      send server, {:VOTE_REQUEST, s.curr_term, %{
        candidateP: s.selfP,
        election: s.curr_election,
        last_term: Log.last_term(s),
        last_index: Log.last_index(s)
      }}
  s |> Debug.message("+vall", "Broadcast vote requests")
end

end # Vote
