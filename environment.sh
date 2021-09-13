#!/bin/bash

set -e
source ./utils.sh


GRID="
...
..o
"

row_idx=0

for line in $GRID; do
	col_idx=0
	for cell in `echo $line | grep -o .`; do
		eval line$col_idx[col_idx]=$cell
		((col_idx += 1))
	done
	((row_idx += 1))
done 

row_length=$row_idx
col_length=$col_idx


move(){
	local state
	state[0]=$1
	state[1]=$2
	local action=$3

	case $action in 
		UP ) state[0]=$((state[0] - 1));;
		DOWN ) (("state[0]" += 1));;
		LEFT ) state[1]=$((state[1] - 1));;
		RIGHT ) (("state[1]" += 1));;
		* ) raise "unexpected action";;
	esac

	if [ ${state[0]} -lt 0 ] || \
			[ ${state[0]} -gt $row_length ] || \
				[ ${state[1]} -lt 0 ] || \
					[ ${state[1]} -gt $col_length  ]; then
		state[0]=$1
		state[1]=$2
	fi

	next_state=${state[@]}
}

transit(){ 
	local state=$1
	local action=$2

	move $state $action
	reward_func $state $next_state
}

step(){
	local action=$1
	local state=STATE
	transit $state $action 
} 

state[0]=0
state[1]=0
move ${state[@]} LEFT
echo ${next_state[@]}
