
# distributed algorithms, n.dulay, 10 jan 22
# basic flooding, v1

defmodule Peer do

  # add your code here, start(), next() and any other functions
  def start(broadcast, peers) do
    IO.puts "--> Peer at #{Helper.node_string()}"

    # start submodules
    beb = spawn(BEB, :start, [peers])
    erb = spawn(ERB, :start, [])
    client = spawn(Client, :start, [erb])
    lpl = spawn(LPL, :start, [beb, 20])

    send beb, {:bind, lpl, erb}
    send erb, {:bind, client, beb}
    send broadcast, {:pl, node(), lpl}

    # id = String.at("#{node()}", 4)
    # if id == "3" do
    #   IO.puts "#{Helper.node_string()} terminating"
    #   Process.sleep(5)
    #   Process.exit(lpl, :kill)
    #   Process.exit(beb, :kill)
    #   Process.exit(erb, :kill)
    #   Process.exit(client, :kill)
    #   Process.exit(self(), :kill)
    # end
  end

end # Peer
