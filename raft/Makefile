# distributed algorithms, n.dulay, 10 jan 22
# coursework, raft
# Makefile, v1

SERVERS   = 5
CLIENTS   = 5

TIMELIMIT = 15000	# quits after milli-seconds(ms)
SETUP     = default	# one of default, slower, faster, etc
# SETUP 	  = server1_3_crash
# SETUP 	  = high_requests
# SETUP 	  = low_vote_timeout



# AppendEntries(areq, arep, atim), Vote(vreq, vrep, vall), Election(etim), DB(dreq, drep), Client(creq, crep)
# Prefixes + for send/send_after,  - for receive
# DEBUG_OPTIONS = "+areq -areq +arep -arep +vreq +vall -vreq +vrep -vrep +atim -atim +etim -etim +dreq -dreq +drep -drep -creq -crep"
# DEBUG_OPTIONS = "!inf ?rec !snd -etim +areq -areq -atim +arep -arep +dreq -dreq +drep -drep -creq -crep +vreq +vall -vreq +vrep -vrep"
DEBUG_OPTIONS = "!inf"

DEBUG_MODE    = off
DEBUG_LEVEL   = 1

START     = Raft.start
HOST	 := 127.0.0.1

###################################
#          Test Case 1            #
###################################
# DEBUG_OPTIONS = "+areq -areq +arep -arep +vreq +vall -vreq +vrep -vrep +atim -atim +etim -etim +dreq -dreq +drep -drep -creq -crep"
# DEBUG_MODE    = TEST_VOTE
# TIMELIMIT 	= 3500
###################################
#          Test Case 2            #
###################################
# DEBUG_MODE  = TEST_CLIENT
# DEBUG_OPTIONS = "-arep"


# --------------------------------------------------------------------

TIME    := $(shell date +%H:%M:%S)
SECS    := $(shell date +%S)
COOKIE  := $(shell echo $$PPID)

NODE_SUFFIX := ${SECS}_${LOGNAME}@${HOST}

ELIXIR  := elixir --no-halt --cookie ${COOKIE} --name
MIX 	:= -S mix run -e ${START} \
	${NODE_SUFFIX} ${TIMELIMIT} ${DEBUG_LEVEL} ${DEBUG_OPTIONS} \
	${SERVERS} ${CLIENTS} ${SETUP} ${DEBUG_MODE}

# --------------------------------------------------------------------

run cluster: compile
	@ echo -------------------------------------------------------------------
	@ ${ELIXIR} server1_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server2_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server3_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server4_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} server5_${NODE_SUFFIX} ${MIX} cluster_wait &

	@ ${ELIXIR} client1_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client2_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client3_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client4_${NODE_SUFFIX} ${MIX} cluster_wait &
	@ ${ELIXIR} client5_${NODE_SUFFIX} ${MIX} cluster_wait &
	@sleep 1
	@ ${ELIXIR} raft_${NODE_SUFFIX} ${MIX} cluster_start

compile:
	mix compile

clean:
	mix clean
	@rm -f erl_crash.dump

ps:
	@echo ------------------------------------------------------------
	epmd -names

unittest:
	mix test test/vote/
