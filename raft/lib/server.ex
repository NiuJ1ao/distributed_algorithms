
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

# Yuchen Niu (yn621) and Zian Wang (zw4821)

defmodule Server do

# s = server process state (c.f. self/this)

# _________________________________________________________ Server.start()
def start(config, server_num) do
  config = config
    |> Configuration.node_info("Server", server_num)
    |> Debug.node_starting()

  crash_timeout = Map.get(config.crash_servers, server_num)
  if crash_timeout != nil do
    Process.send_after(self(), :CRASH_TIMEOUT, crash_timeout)
  end

  receive do
  { :BIND, servers, databaseP } ->
    State.initialise(config, server_num, servers, databaseP)
      |> Timer.restart_election_timer()
      |> Server.next()

  { :TEST_FOLLOWER, servers, databaseP } ->
    Map.put(config, :leader_pid, Enum.at(servers, 0))
    State.initialise(config, server_num, servers, databaseP)
      |> Timer.restart_election_timer()
      |> Server.test_follower()

  { :TEST_LEADER, servers, databaseP } ->
    Map.put(config, :leader_pid, Enum.at(servers, 0))
    # make LEADER crash
    Process.send_after(self(), :VOTE_TEST_TIMEOUT, 2000)

    State.initialise(config, server_num, servers, databaseP)
      |> Timer.restart_election_timer()
      |> Server.test_leader()

  end # receive
end # start

def test_follower(s) do
  s = receive do
    { :VOTE_REQUEST, mterm, m } = msg ->                      # Candidate >> All
    s |> Debug.message("-vreq", "Recive a vote request from server")
      |> Vote.receive_vote_request_from_candidate(mterm, m)

    { :ELECTION_TIMEOUT, _mterm, _melection } = msg ->        # Self {Follower, Candidate} >> Self
    s |> Debug.message("-etim", "Update Client Timer")
      |> Timer.restart_election_timer()

    unexpected = msg ->
      s |> Debug.received("#{inspect msg}")

  end # receive
  Server.test_follower(s)
end   # def

def test_leader(s) do
  s = receive do
    { :ELECTION_TIMEOUT, _mterm, _melection } = msg ->        # Self {Follower, Candidate} >> Self
    s |> Debug.message("-etim", msg)
      |> Vote.receive_election_timeout()

    { :VOTE_REPLY, mterm, m } = msg ->                        # Follower >> Candidate
    if m.election < s.curr_election do
      s |> Debug.received("Discard Reply to old Vote Request #{inspect msg}")
    else
      s |> Debug.message("-vrep", msg)
        |> Vote.receive_vote_reply_from_follower(mterm, m)
    end # if

    :VOTE_TEST_TIMEOUT ->
      Helper.node_halt("Server#{s.server_num} crashed")

    unexpected = msg ->
      s |> Debug.received("#{inspect msg}")

  end   # receive
  Server.test_leader(s)
end     # defp

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
  {:DB_REPLY, m} ->
    # request = Log.request_at(s, s.last_applied)
    send m.clientP, {:CLIENT_REPLY, m.cid, m.result, s.leaderP}
    s |> Debug.message("-drep", "Database reply #{inspect {m.cid, m.result, s.leaderP}}")

  :CRASH_TIMEOUT ->
    Helper.node_halt("Server#{s.server_num} crashed")

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
  # entries must be committed before applying
  if s.commit_index > s.last_applied do
    # increment last applied
    s = s |> State.last_applied(s.last_applied + 1)

    # apply log[last_applied] to state machine
    send s.databaseP, {
      :DB_REQUEST, Log.request_at(s, s.last_applied)
    }
    # receive do
    #   {:DB_REPLY, m} ->
    #     request = Log.request_at(s, s.last_applied)
    #     send request.clientP, {:CLIENT_REPLY, request.cid, m, s.leaderP}
    #     s |> Debug.message("-drep", "Database reply #{inspect {request.cid, m, s.leaderP}}")
    # end
    s
  else
    s
  end # if
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
