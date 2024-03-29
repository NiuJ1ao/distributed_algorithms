
# distributed algorithms, n.dulay, 8 feb 2022
# raft, configuration parameters v2

defmodule Configuration do

# _________________________________________________________ node_init()
def node_init() do
  # get node arguments and spawn a process to exit node after max_time
  config =
    %{
      node_suffix:    Enum.at(System.argv, 0),
      raft_timelimit: String.to_integer(Enum.at(System.argv, 1)),
      debug_level:    String.to_integer(Enum.at(System.argv, 2)),
      debug_options:  "#{Enum.at(System.argv, 3)}",
      n_servers:      String.to_integer(Enum.at(System.argv, 4)),
      n_clients:      String.to_integer(Enum.at(System.argv, 5)),
      setup:          :'#{Enum.at(System.argv, 6)}',
      debug_mode:     :'#{Enum.at(System.argv, 7)}',
      start_function: :'#{Enum.at(System.argv, 8)}',
    }

  if config.n_servers < 3 do Helper.node_halt("Raft is unlikely to work with fewer than 3 servers") end

  spawn(Helper, :node_exit_after, [config.raft_timelimit])

  config |> Map.merge(Configuration.params(config.setup))
end # node_init

# _________________________________________________________ node_info()
def node_info(config, node_type, node_num \\ "") do
  Map.merge config,
  %{
    node_type:     node_type,
    node_num:      node_num,
    node_name:     "#{node_type}#{node_num}",
    node_location: Helper.node_string(),
    line_num:      0,  # for ordering output lines
  }
end # node_info

# _________________________________________________________ params :default ()
def params :default do
  %{
    n_accounts:              100,      # account numbers 1 .. n_accounts
    max_amount:              1_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5_000,        # maximum no of requests each client will attempt
    client_request_interval: 5,        # interval(ms) between client requests
    client_reply_timeout:    50,      # timeout(ms) for the reply to a client request

    election_timeout_range:  100..200, # timeout(ms) for election, set randomly in range
    append_entries_timeout:  10,       # timeout(ms) for the reply to a append_entries request

    dummy_time_interval:     10,

    monitor_interval:        500,      # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
      # 1 => 5_000,
      # 5 => 5_000,
      # 4 => 15_000,
    }
  }
end # params :default

def params :leader_crash do # if server 1 or server 5 is not leader, run again
  %{
    n_accounts:              100,      # account numbers 1 .. n_accounts
    max_amount:              1_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5_000,        # maximum no of requests each client will attempt
    client_request_interval: 5,        # interval(ms) between client requests
    client_reply_timeout:    50,      # timeout(ms) for the reply to a client request

    election_timeout_range:  100..200, # timeout(ms) for election, set randomly in range
    append_entries_timeout:  10,       # timeout(ms) for the reply to a append_entries request

    dummy_time_interval:     10,

    monitor_interval:        500,      # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
      1 => 5_000,
      5 => 5_000,
    }
  }
end

def params :long_append_entries do
  %{
    n_accounts:              100,      # account numbers 1 .. n_accounts
    max_amount:              1_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5_000,        # maximum no of requests each client will attempt
    client_request_interval: 5,        # interval(ms) between client requests
    client_reply_timeout:    50,      # timeout(ms) for the reply to a client request

    election_timeout_range:  100..200, # timeout(ms) for election, set randomly in range
    append_entries_timeout:  1000,       # timeout(ms) for the reply to a append_entries request

    dummy_time_interval:     10,

    monitor_interval:        500,      # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
      # 1 => 5_000,
      # 5 => 5_000,
    }
  }
end

def params :low_election_timeout do
  %{
    n_accounts:              100,      # account numbers 1 .. n_accounts
    max_amount:              1_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5_000,        # maximum no of requests each client will attempt
    client_request_interval: 5,        # interval(ms) between client requests
    client_reply_timeout:    50,      # timeout(ms) for the reply to a client request

    election_timeout_range:  10..10, # timeout(ms) for election, set randomly in range
    append_entries_timeout:  10,       # timeout(ms) for the reply to a append_entries request

    dummy_time_interval:     10,

    monitor_interval:        500,      # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
      # 1 => 5_000,
      # 5 => 5_000,
    }
  }
end

def params :low_vote_timeout do
  %{
    n_accounts:              100,      # account numbers 1 .. n_accounts
    max_amount:              1_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5_000,        # maximum no of requests each client will attempt
    client_request_interval: 5,        # interval(ms) between client requests
    client_reply_timeout:    50,      # timeout(ms) for the reply to a client request

    election_timeout_range:  30..70,  # timeout(ms) for election, set randomly in range
    append_entries_timeout:  50,       # timeout(ms) for the reply to a append_entries request

    monitor_interval:        500,      # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
    }
  }
end

  def params :high_requests do
  %{
    n_accounts:              1000,      # account numbers 1 .. n_accounts
    max_amount:              1_000_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5_0000,       # maximum no of requests each client will attempt
    client_request_interval: 2,        # interval(ms) between client requests
    client_reply_timeout:    50,      # timeout(ms) for the reply to a client request

    election_timeout_range:  100..200, # timeout(ms) for election, set randomly in range
    append_entries_timeout:  10,       # timeout(ms) for the reply to a append_entries request

    monitor_interval:        500,      # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
    }
  }
end

  def params :server1_3_crash do
  %{
    n_accounts:              100,      # account numbers 1 .. n_accounts
    max_amount:              1_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5_000,        # maximum no of requests each client will attempt
    client_request_interval: 5,        # interval(ms) between client requests
    client_reply_timeout:    50,      # timeout(ms) for the reply to a client request

    election_timeout_range:  100..200, # timeout(ms) for election, set randomly in range
    append_entries_timeout:  10,       # timeout(ms) for the reply to a append_entries request

    monitor_interval:        500,      # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
      1 => 1500,
      3 => 5000,
    }
  }
end

# _________________________________________________________ params :slower ()
def params :slower do              # settingsto slow timing
  Map.merge (params :default),
  %{
  }
end # params :slower



end # Configuration
