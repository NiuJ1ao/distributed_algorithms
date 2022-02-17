defmodule VoteTest do
  use ExUnit.Case
  doctest Raft

  defp get_test_config do
    config =
      %{
        node_suffix:    "test",
        raft_timelimit: 15000,
        debug_level:    0,
        debug_options:  "none",
        n_servers:      3,
        n_clients:      3,
        setup:          :default,
        start_function: :cluster_start,
      }

    if config.n_servers < 3 do Helper.node_halt("Raft is unlikely to work with fewer than 3 servers") end

    spawn(Helper, :node_exit_after, [config.raft_timelimit])

    config |> Map.merge(Configuration.params(config.setup))
  end

  setup do
    servers = [self()]
    %{
      # _____________________constants _______________________

      config:       get_test_config(),             # system configuration parameters (from Helper module)
      server_num:	  3,                  # server num (for debugging)
      selfP:        self(),             # server's process id
      servers:      servers,            # list of process id's of servers
      num_servers:  length(servers),    # no. of servers
      majority:     div(length(servers),2) + 1,  # cluster membership changes are not supported in this implementation

      databaseP:    nil,          # local database - used to send committed entries for execution

      # ______________ elections ____________________________
      election_timer:  nil,            # one timer for all peers
      curr_election:   0,              # used to drop old electionTimeout messages and votereplies
      voted_for:	     nil,            # num of candidate that been granted vote incl self
      voted_by:        MapSet.new,     # set of processes that have voted for candidate incl. candidate

      append_entries_timers: Map.new,   # one timer for each follower

      leaderP:        nil,	     # included in reply to client request

      # _______________raft paper state variables___________________

      curr_term:	  0,                  # current term incremented when starting election
      log:          Log.new(),          # log of entries, indexed from 1
      role:         :CANDIDATE,          # one of :FOLLOWER, :LEADER, :CANDIDATE
      commit_index: 0,                  # index of highest committed entry in server's log
      last_applied: 0,                  # index of last entry applied to state machine of server

      next_index:   Map.new,            # foreach follower, index of follower's last known entry+1
      match_index:  Map.new,            # index of highest entry known to be replicated at a follower
    }
  end

  describe "Unit tests for vote.ex" do
    test "test receive_election_timeout", s do
      s = s |> Vote.receive_election_timeout
      assert s.role == :CANDIDATE
      assert s.curr_election == 1
      assert s.curr_term == 1
      assert s.voted_for == self()
    end
  end

end
