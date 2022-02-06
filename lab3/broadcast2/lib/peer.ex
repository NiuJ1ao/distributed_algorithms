
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

defmodule Peer do

  # add your code here, start(), next() and any other functions
  def start(broadcast) do
    IO.puts "--> Peer at #{Helper.node_string()}"

    # start submodules
    client = spawn(Client, :start, [])
    pl = spawn(PL, :start, [client])

    send client, {:bind, pl}
    send broadcast, {:pl, node(), pl}
  end

end # Peer
