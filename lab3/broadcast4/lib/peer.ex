
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

defmodule Peer do

  # add your code here, start(), next() and any other functions
  def start(broadcast, peers) do
    IO.puts "--> Peer at #{Helper.node_string()}"

    # start submodules
    beb = spawn(BEB, :start, [peers])
    client = spawn(Client, :start, [beb])
    lpl = spawn(LPL, :start, [beb, 20])

    send beb, {:bind, lpl, client}
    send broadcast, {:pl, node(), lpl}
  end

end # Peer
