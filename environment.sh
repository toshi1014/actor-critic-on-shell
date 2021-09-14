#!/bin/bash

set -e
source ./utils.sh
source ./config.txt

readonly GRID
readonly GOAL
readonly FAIL
readonly DEFAULT_REWARD
readonly ACTION_LIST


read_grid(){
	local _row_idx=0

	for line in $GRID; do
		local _col_idx=0
		for cell in `echo $line | grep -o .`; do
			eval grid_line$_row_idx[_col_idx]=$cell
			((_col_idx += 1))
		done
		((_row_idx += 1))
	done 

	row_length=$_row_idx
	col_length=$_col_idx
}



move(){
	local _state=($1 $2)
	local _action=$3

	case $_action in 
		${ACTION_LIST[0]} ) _state[0]=$((_state[0] - 1));;
		${ACTION_LIST[1]} ) (("_state[0]" += 1));;
		${ACTION_LIST[2]} ) _state[1]=$((_state[1] - 1));;
		${ACTION_LIST[3]} ) (("_state[1]" += 1));;
		* ) raise "unexpected action $_action";;
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
	local _col=${_next_state[1]}

	eval local _grid_line=(\${grid_line$_row[@]}) 
	
	done=true

	case ${_grid_line[$_col]} in
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


read_grid

if [ $BASH_SOURCE = $0 ]; then
	state[0]=0
	state[1]=0

	step DOWN
	echo -e "state:\t${state[@]}" 
	echo -e "reward:\t$reward"
	echo -e "done:$done"
fi
