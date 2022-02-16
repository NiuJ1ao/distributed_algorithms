
# distributed algorithms, n.dulay, 8 feb 2022
# coursework, raft consensus, v2

defmodule AppendEntries do

# s = server process state (c.f. this/self)

# TODO: commit

# ________________________________________________________________________Leader >> Follower
def send_append_entries_request_to_follower(s, followerP) do
  # In the slide, they use index that is chosen from a range. why?
  last_log_index = s.next_index[followerP] - 1

  s = s |> Timer.restart_append_entries_timer(followerP)

  msg = if last_log_index == 0 do
    s |> Debug.message("+areq", "HEARTBEAT")
    {:APPEND_ENTRIES_REQUEST, s.curr_term, %{leaderP: s.selfP}}
  else
    {:APPEND_ENTRIES_REQUEST, s.curr_term, %{
      leaderP: s.selfP,
      prev_index: last_log_index - 1,
      prev_term: Log.term_at(s, last_log_index - 1),
      entries: Log.get_entries(s, [last_log_index..Log.last_index(s)]),
      commit_index: s.commit_index,
    }}
  end

  send followerP, msg
  s |> Debug.message("+areq", "#{inspect msg}")
end # send_append_entries_request_to_follower

# ________________________________________________________________________ Leader >> All
def broadcast_append_entries_request_from_leader(s) do
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
  s |> send_entries_reply_to_leader(leaderP, false, nil)
end # send_entries_reply_to_leader

# ________________________________________________________________________ Follower >> Leader
def send_entries_reply_to_leader(s, leaderP, success, index) do
  send leaderP, {:APPEND_ENTRIES_REPLY, s.term, %{
      followerP: s.selfP,
      success: success,
      index: index
  }}
  s |> Debug.message("+arep", "Send #{success} to #{inspect leaderP}")
end # send_entries_reply_to_leader

# ________________________________________________________________________ Leader >> Follower
def receive_append_entries_request_from_leader(s, mterm, m) when map_size(m) == 1 do
  s |> Debug.message("-areq", "HEARTBEAT")
    |> Server.become_follower(mterm)
    |> State.leaderP(m.leaderP)
end # receive_append_entries_request_from_leader

# ________________________________________________________________________ Leader >> Follower
def receive_append_entries_request_from_leader(s, mterm, m) do
  s = s |> Server.become_follower(mterm)
        |> State.leaderP(m.leaderP)

  # AppendEntries consistency check
  success = m.prev_index == 0 or (
    m.prev_index < Log.last_index(s) and
    m.prev_term == Log.term_at(s, m.prev_index)
  )

  {s, index} =
    if success do
      s |> store_entries(m.prev_index, m.entries, m.commit_index)
    else
      {s, 0}
    end

  s |> send_entries_reply_to_leader(s.leaderP, success, index)
end # receive_append_entries_request_from_leader

defp store_entries(s, prev_index, entries, commit_index) do
  start = prev_index + 1
  last = start + Enum.count(entries)
  # delete extraneous entries
  s =
    if last < Log.last_index(s) do
      s |> Log.delete_entries(start..last)
    else
      s |> Log.delete_entries_from(start)
    end
  # fill in missing entries
  s =
    s |> Log.merge_entries(entries)
      |> State.commit_index(min(commit_index, last))
  {s, last}
end # store_entries

# ________________________________________________________________________ Follower >> Leader
def receive_append_entries_reply_from_follower(s, mterm, m) do
  cond do
    mterm > s.term ->
      s |> Server.follower_if_higher(mterm)
    s.role == :LEADER and mterm == s.curr_term ->
      s =
        if m.success do
          # update match index and next index
          s |> State.next_index(m.followerP, m.index + 1)
            |> State.match_index(m.followerP, m.index)
        else
          # decrement next index
          s |> State.next_index(m.followerP, max(1, s.next_index[m.followerP] - 1))
        end
      if s.next_index[m.followerP] <= Log.last_index(s) do # retry at previous index
        s |> send_append_entries_request_to_follower(m.followerP)
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
