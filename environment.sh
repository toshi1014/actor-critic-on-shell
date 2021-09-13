#!/bin/bash

set -e
source ./utils.sh


readonly GRID="
...
..o
" 
readonly GOAL=o
readonly FAIL=x
readonly DEFAULT_REWARD=-0.04


row_idx=0

for line in $GRID; do
	col_idx=0
	for cell in `echo $line | grep -o .`; do
		eval line$row_idx[col_idx]=$cell
		((col_idx += 1))
	done
	((row_idx += 1))
done 

row_length=$row_idx
col_length=$col_idx


move(){
	local _state=($1 $2)
	local _action=$3

	case $_action in 
		UP ) _state[0]=$((_state[0] - 1));;
		DOWN ) (("_state[0]" += 1));;
		LEFT ) _state[1]=$((_state[1] - 1));;
		RIGHT ) (("_state[1]" += 1));;
		* ) raise "unexpected action";;
	esac

	if [ ${_state[0]} -lt 0 ] || \
			[ ${_state[0]} -gt $row_length ] || \
				[ ${_state[1]} -lt 0 ] || \
					[ ${_state[1]} -gt $col_length  ]; then
		_state=($1 $2)
	fi

	next_state=(${_state[@]})
}


reward_func(){
	local _state=($1 $2)
	local _next_state=($3 $4)

	local _row=${_next_state[0]}
	local _col=${_state[1]}

	eval local _line=(\${line$_row[@]}) 
	
	done=true

	case ${_line[$_col]} in
		$GOAL ) reward=1;;
		$FAIL ) reward=-1;;
		* ) reward=$DEFAULT_REWARD
			done=false;;
	esac 
}


transit(){ 
	local _state=($1 $2)
	local _action=$3

	move ${_state[@]} $_action 
	reward_func ${_state[@]} ${next_state[@]} 
}


step(){
	local _action=$1
	transit ${state[@]} $_action 
	state=(${next_state[@]})
} 


if [ $BASH_SOURCE = $0 ]; then
	state[0]=0
	state[1]=0

	step DOWN
	echo -e "state:\t${state[@]}" 
	echo -e "reward:\t$reward"
	echo -e "done:$done"
fi
