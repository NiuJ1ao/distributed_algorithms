
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule Server do

# s = server process state (c.f. self/this)

# _________________________________________________________ Server.start()
def start(config, server_num) do
  config = config
    |> Configuration.node_info("Server", server_num)
    |> Debug.node_starting()

  receive do
  { :BIND, servers, databaseP } ->
    State.initialise(config, server_num, servers, databaseP)
      |> Timer.restart_election_timer()
      |> Server.next()
  end # receive
end # start

# _________________________________________________________ next()
def next(s) do
  s = s |> Server.execute_committed_entries()

  curr_term = s.curr_term                          # used to discard old messages
  curr_election = s.curr_election                  # used to discard old election timeouts

  s = receive do

  # ________________________________________________________
  { :APPEND_ENTRIES_REQUEST, mterm, m } when mterm < curr_term -> # Reject send Success=false and newer term in reply
    s |> Debug.message("-areq", "stale #{mterm} #{inspect m}")
      |> AppendEntries.send_entries_reply_to_leader(m.leaderP, false)

  # ________________________________________________________
  { :VOTE_REQUEST, mterm, m } when mterm < curr_term ->     # Reject, send votedGranted=false and newer_term in reply
    s |> Debug.message("-vreq", "stale #{mterm} #{inspect m}")
      |> Vote.send_vote_reply_to_candidate(m.candidateP, false)

  # ________________________________________________________
  { _mtype, mterm, _m } = msg when mterm < curr_term ->     # Discard any other stale messages
    s |> Debug.received("stale #{inspect msg}")

  # ________________________________________________________
  { :APPEND_ENTRIES_REQUEST, mterm, m } = msg ->            # Leader >> All
    s |> Debug.message("-areq", msg)
      |> AppendEntries.receive_append_entries_request_from_leader(mterm, m)

  { :APPEND_ENTRIES_REPLY, mterm, m } = msg ->              # Follower >> Leader
    s |> Debug.message("-arep", msg)
      |> AppendEntries.receive_append_entries_reply_from_follower(mterm, m)

  { :APPEND_ENTRIES_TIMEOUT, _mterm, followerP } = msg ->   # Leader >> Leader
    s |> Debug.message("-atim", msg)
      |> AppendEntries.receive_append_entries_timeout(followerP)

  # ________________________________________________________
  { :VOTE_REQUEST, mterm, m } = msg ->                      # Candidate >> All
    s |> Debug.message("-vreq", msg)
      |> Vote.receive_vote_request_from_candidate(mterm, m)

  { :VOTE_REPLY, mterm, m } = msg ->                        # Follower >> Candidate
    if m.election < curr_election do
      s |> Debug.received("Discard Reply to old Vote Request #{inspect msg}")
    else
      s |> Debug.message("-vrep", msg)
        |> Vote.receive_vote_reply_from_follower(mterm, m)
    end # if

  # ________________________________________________________
  { :ELECTION_TIMEOUT, _mterm, melection } = msg when melection < curr_election ->
    s |> Debug.received("Old Election Timeout #{inspect msg}")

  { :ELECTION_TIMEOUT, _mterm, _melection } = msg ->        # Self {Follower, Candidate} >> Self
    s |> Debug.message("-etim", msg)
      |> Vote.receive_election_timeout()

  # ________________________________________________________
  { :CLIENT_REQUEST, m } = msg ->                           # Client >> Leader
    s |> Debug.message("-creq", msg)
      |> ClientReq.receive_request_from_client(m)

  # { :DB_RESULT, _result } when false -> # don't process DB_RESULT here

  unexpected ->
    Helper.node_halt("************* Server: unexpected message #{inspect unexpected}")

  end # receive

  Server.next(s)
end # next

# """  Omitted
# def follower_if_higher(s, mterm) do
# def become_leader(s) do
# def become_candidate(s) do
# def become_follower(s, mterm) do
# def execute_committed_entries(s) do
# """

def execute_committed_entries(s) do
  # # entries must be committed before applying
  # if s.commit_index > s.last_applied do
  #   # increment last applied
  #   s = s |> State.last_applied(s.last_applied + 1)

  #   # apply log[last_applied] to state machine
  #   send s.databaseP, {
  #     :DB_REQUEST, Log.request_at(s, s.last_applied)
  #   }
  #   s
  # else
  #   s
  # end # if
  s
end # execute_committed_entries

def become_follower(s, mterm) do
  s |> State.curr_term(mterm)
    |> Timer.restart_election_timer()
    |> State.role(:FOLLOWER)
    |> State.voted_for(nil)
end

# step down
def follower_if_higher(s, mterm) do
  s |> Server.become_follower(mterm)
    |> Debug.received("Step Down! Become follower.")
end

end # Server
