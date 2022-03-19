defmodule Flooding_uniform_consensus do
def start do
  receive do
    { :bind, c, beb, n, processes } ->
    next c, beb, n, processes, 1, nil, MapSet.new, MapSet.new
  end
end

defp next c, beb, n, correct, round, value_decided, proposal_set, proposer_set do
  receive do
    { :pfd_crash, crashedP } -> # from PFD
      correct = Map.delete(correct, crashedP)
      send self(), { :check_if_consensus }
      next <n-1>, <correct>
    { :uc_propose, value } -> # proposed value from c
      proposal_set = MapSet.put(proposal_set, value)
      proposer_set = MapSet.put(proposer_set, self())
      send beb, { :beb_broadcast, { :uc_propose, proposal_set, round, self() } }
      next <proposal_set>, <proposer_set>
    { :beb_deliver, proposer, {mproposals, mround, mproposer} = msg } when round == mround ->
      if Enum.count(proposer_set) >= n do
        send self(), { :check_if_consensus }
      else
        proposal_set = MapSet.union(proposal_set, mproposals)
        proposer_set = MapSet.put(proposer_set, mproposer)
        next <proposal_set>, <proposer_set>
      end

    { :check_if_consensus } -> # and deliver if conditions ok
      if round == n do
        minimum = Enum.min(proposal_set)
        send c, { :uc_deliver, minimum }
        next <round=1>, <value_decided=minimum>, <proposal_set=MapSet.new> <proposer_set=MapSet.new>
      else
        next <round+1>, <proposal_set=MapSet.new>, <proposer_set=MapSet.new>
      end
  end
end
