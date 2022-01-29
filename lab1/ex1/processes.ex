
# distributed algorithms, n.dulay, 10 jan 21
# time how long it takes to create N processes and receive an :ok reply 

defmodule Processes do

def start do
  create(100_000)
end # start

defp create(n) do
  parent = self()		# get our process id
  start  = Time.utc_now()	# get current time

  # spawn n processes - coded as an anonymous function
  # each process will send an :ok message back to parent process 
  Enum.map(1..n, fn(_) -> spawn(fn -> send parent, :ok end) end)
  # Using Enum.each will be equivalent to Enum.map, but slower (try it)
  # Enum.each(1..n, fn(_) -> spawn(fn -> send parent, :ok end) end)

  # receive :ok message from each spawned processes
  # essentially runs receive_ok_reply n times
  Enum.each(1..n, &receive_ok_reply/1)

  finish = Time.utc_now()

  duration = Time.diff(finish, start, :millisecond)

  IO.puts "Processes     = #{n}"
  IO.puts "Max processes = #{:erlang.system_info(:process_limit)}"
  IO.puts "Total time    = #{duration} milliseconds"
  IO.puts "Process time  = #{duration * 1000 / n} microseconds"
end # create

defp receive_ok_reply(_) do
  receive do
    :ok -> :ok
  end # receive
end # receive_ok_reply

end # Processes

