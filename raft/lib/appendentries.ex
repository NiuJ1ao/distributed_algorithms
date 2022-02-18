
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule AppendEntries do

# s = server process state (c.f. this/self)

# ________________________________________________________________________Leader >> Follower
def send_append_entries_request_to_follower(s, followerP) do
  last_log_index = s.next_index[followerP]

  s = s |> Timer.restart_append_entries_timer(followerP)

  msg =
    if last_log_index > 0 and last_log_index <= Log.last_index(s) do
      # get previous entry (index and term) for consistency check
      prev_index = last_log_index - 1
      prev_term =
        if prev_index > 0 do
          Log.term_at(s, prev_index)
        else
          0
        end
      entries = Log.get_entries(s, last_log_index..Log.last_index(s))  # send multiple entries for efficiency
      s |> Debug.message("+areq", "#{inspect s.log}[#{last_log_index}..#{Log.last_index(s)}] => #{inspect entries}")
      s |> Debug.assert(map_size(entries) > 0, "Send AppendReq: entries is empty")
      {:APPEND_ENTRIES_REQUEST, s.curr_term, %{
        leaderP: s.selfP,
        prev_index: prev_index,
        prev_term: prev_term,
        entries: entries,
        commit_index: s.commit_index,
      }}
    else
      # no log or waitting for new client request, send empty areq as heartbeat
      s |> Debug.message("+areq", "HEARTBEAT", 2)
      {:APPEND_ENTRIES_REQUEST, s.curr_term, %{
        leaderP: s.selfP,
        prev_index: Log.last_index(s),
        prev_term: Log.last_term(s),
        entries: %{},
        commit_index: s.commit_index,
      }}
    end

  send followerP, msg
  s |> Debug.message("+areq", "#{inspect msg}")
end # send_append_entries_request_to_follower

# ________________________________________________________________________ Leader >> All
def broadcast_append_entries_request_to_follower(s) do
  s = s |> Debug.message("+areq", "Broadcast APPEND_ENTRIES_REQUEST")
  Enum.reduce(s.servers, s, fn(x, y) ->
    if x != y.selfP do
      y |> send_append_entries_request_to_follower(x)
    else
      y
    end
  end)
end # broadcast_append_entries_request_from_leader

# ________________________________________________________________________ Follower >> Leader
def send_entries_reply_to_leader(s, leaderP, false) do
  s |> Server.become_follower(s.curr_term)
    |> send_entries_reply_to_leader(leaderP, false, nil)
end # send_entries_reply_to_leader

# ________________________________________________________________________ Follower >> Leader
def send_entries_reply_to_leader(s, leaderP, success, index) do
  send leaderP, {:APPEND_ENTRIES_REPLY, s.curr_term, %{
      followerP: s.selfP,
      success: success,
      index: index
  }}
  s |> Debug.message("+arep", "Send reply to leader: #{success} with match index #{index}")
end # send_entries_reply_to_leader

# # ________________________________________________________________________ Leader >> Follower
# def receive_append_entries_request_from_leader(s, mterm, m) when map_size(m) == 1 do
#   s |> Debug.message("-areq", "HEARTBEAT", 2)
#     |> Server.become_follower(mterm)
#     |> State.leaderP(m.leaderP)
# end # receive_append_entries_request_from_leader

# ________________________________________________________________________ Leader >> Follower
def receive_append_entries_request_from_leader(s, mterm, m) do
  s = s |> Server.become_follower(mterm)
        |> State.leaderP(m.leaderP)

  # AppendEntries consistency check
  success = m.prev_index == 0 or (
    m.prev_index <= Log.last_index(s) and       # log is long enough
    m.prev_term == Log.term_at(s, m.prev_index) # term matched at prev_index
  )

  {s, index} =
    if success do
      s |> store_entries(m.prev_index, m.entries, m.commit_index)
    else
      {s, 0}
    end

  if map_size(m.entries) == 0 do
    s |> Debug.message("-areq", "HEARTBEAT")
  else
    s |> Debug.assert(index > 0, "Recv AppendReq: matched index is 0")
  end

  s |> Debug.message("-areq", "Store entires with match index #{index}: #{success}")
    |> Debug.message("-areq", "Follower log update: #{inspect s.log}")
    |> send_entries_reply_to_leader(s.leaderP, success, index)
end # receive_append_entries_request_from_leader

defp store_entries(s, prev_index, entries, commit_index) do
  start = prev_index + 1
  match_index = start - 1 + map_size(entries)

  # delete extraneous entries
  s |> Debug.message("-areq", "Log before deletion: #{inspect s.log}")
  s = s |> Log.delete_entries_from(start)
  s |> Debug.message("-areq", "Log after deletion: #{inspect s.log} from #{start}")
  # fill in missing entries
  s =
    s |> Log.merge_entries(entries)
      |> State.commit_index(min(commit_index, match_index)) # this could decrease commit index
  s |> Debug.message("-areq", "Update commit index = #{s.commit_index}")
  {s, match_index}
end # store_entries

# ________________________________________________________________________ Follower >> Leader
def receive_append_entries_reply_from_follower(s, mterm, m) do
  cond do
    mterm > s.curr_term ->
      s |> Server.follower_if_higher(mterm)
    s.role == :LEADER and mterm == s.curr_term ->
      s =
        if m.success do
          # update match index and next index
          s = s |> State.next_index(m.followerP, m.index + 1)
                |> State.match_index(m.followerP, m.index)

          s |> Debug.message("-arep", "Update next_index = #{s.next_index[m.followerP]}, match_index = #{s.match_index[m.followerP]} of a follower")

          # entry committed if known to be stored on majority of servers
          count = Enum.count(s.match_index, fn({_, x}) -> x > s.commit_index end)
          s |> Debug.message("-arep", "Count of entry committed = #{count}")
          if count >= s.majority do
            s = s |> State.commit_index(s.commit_index + 1)
            s |> Debug.message("-arep", "Update commit index = #{s.commit_index} and broadcast")
              |> broadcast_append_entries_request_to_follower() # let followers know about the new commit index
          else
            s
          end
        else
          # decrement next index if not success
          s |> State.next_index(m.followerP, max(1, s.next_index[m.followerP] - 1))
            |> Debug.message("-arep", "Decrement next index.")
        end
      if s.next_index[m.followerP] <= Log.last_index(s) do # retry at previous index
        s |> Debug.message("-arep", "Retry at a new previous index")
          |> send_append_entries_request_to_follower(m.followerP)
      else
        s
      end
    true ->
      s
  end
end # receive_append_entries_reply_from_follower

# ________________________________________________________________________ Leader >> Leader
def receive_append_entries_timeout(s, followerP) do
  if s.role == :LEADER do
    s |> Timer.restart_append_entries_timer(followerP)
      |> send_append_entries_request_to_follower(followerP)
  else
    s |> Timer.cancel_all_append_entries_timers()
  end
end # receive_append_entries_timeout

end # AppendEntriess
