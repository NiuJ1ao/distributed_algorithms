
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule Vote do

# s = server process state (c.f. self/this)

# def send_vote_reply_to_candidate(s, m.candidateP, voteGranted) do

# end

# def receive_vote_request_from_candidate(mterm, m) do

# end

# def receive_vote_reply_from_follower(mterm, m) do

# end

def receive_election_timeout(s) do
  if s.role = :FOLLOWER or s.role = :CANDIDATE do
    # set new timeout
    new_election_timer  = rand:uniform(1, 2) * s[:election_timeout]
    s |> State.election_timer(new_election_timer)

    # increment current term
    s |> State.inc_election()

    # change to candidate
    s |> Server.become_candidate()

    # vote for self
    s |> State.voted_for(0)
    s |> State.new_voted_by()
    s |> State.add_to_voted_by(s[:selfP])

    #

  end
end

end # Vote
