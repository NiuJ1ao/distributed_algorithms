defmodule VoteTest do
  use ExUnit.Case
  doctest Raft

  # setup_all do
  #   config = get_test_config()
  #   Raft.start(config, config.start_function)
  #   []
  # end

  # defp get_test_config do
  #   config =
  #     %{
  #       node_suffix:    "test",
  #       raft_timelimit: 15000,
  #       debug_level:    0,
  #       debug_options:  "none",
  #       n_servers:      3,
  #       n_clients:      3,
  #       setup:          :default,
  #       start_function: :cluster_start,
  #     }

  #   if config.n_servers < 3 do Helper.node_halt("Raft is unlikely to work with fewer than 3 servers") end

  #   spawn(Helper, :node_exit_after, [config.raft_timelimit])

  #   config |> Map.merge(Configuration.params(config.setup))
  # end

  describe "Unit tests for vote.ex" do
    test "greets the world" do

    end
  end

end
