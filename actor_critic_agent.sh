#!/bin/bash

set -e 
source ./environment.sh

readonly MAX_EPISODE
readonly GAMMA
readonly LEARNING_RATE_ACTOR
readonly LEARNING_RATE_CRITIC


init_V(){
	for (( i=0; i<$row_length; i++  )){
		for (( j=0; j<$col_length; j++  )){
			eval V_line$i[j]=0
		}
	} 
}


init_Q(){
	for (( i=0; i<$row_length; i++  )){
		for (( j=0; j<$col_length; j++  )){
			for (( k=0; k<${#ACTION_LIST[@]}; k++  )){
				eval Q_line${i}_col${j}[k]=0
			}
		}
	} 
}


get_V_value(){
	local _state=($1 $2)
	local _var_name=$3
	local _row=${_state[0]}
	local _col=${_state[1]}

	eval $_var_name=\${V_line${_row}[$_col]}
}


get_Q_now(){ 
	local _state=($1 $2)
	local _action_idx=$3

	local _target_Q=Q_line${_state[0]}_col${_state[1]}[$_action_idx]
	eval Q_now=\${$_target_Q}
}


policy(){
	local _state=($1 $2)
	declare -ag value_list

	for (( i=0; i<${#ACTION_LIST[@]}; i++ )){
		get_Q_now ${_state[@]} $i
		value_list+=($Q_now)
	} 

	get_softmax
	get_chosen_idx

	action=${ACTION_LIST[$chosen_idx]}
}


get_gain(){
	gain=`echo "scale=5; $reward + $GAMMA * $V_next" | bc`
}


get_td(){
	td=`echo "scale=5; $gain - $V_now" | bc`
}


update_V_Q(){ 
	## for critic
	local _state_now=($1 $2)
	local _row=${_state_now[0]}
	local _col=${_state_now[1]}

	local _weighted_td_critic=`echo "scale=5; $LEARNING_RATE_CRITIC * $td" | bc`

	local _target_V=V_line${_row}[$_col]
	local _new_V=`echo "scale=5; $_weighted_td_critic + $V_now" | bc`
	eval $_target_V=$_new_V 

	## for actor
	local _weighted_td_actor=`echo "scale=5; $LEARNING_RATE_ACTOR * $td" | bc`

	for (( i=0; i< "${#ACTION_LIST[@]}"; i++)){ 
		if [ ${ACTION_LIST[i]} = $action  ]; then
			local _action_idx=$i
		fi
	}

	get_Q_now ${_state_now[@]} $_action_idx
	local _target_Q=Q_line${_row}_col${_col}[$_action_idx]
	local _new_Q=`echo "scale=5; $_weighted_td_actor + $Q_now" | bc` 
	eval $_target_Q=$_new_Q
}


learn(){
	for (( i=0; i<MAX_EPISODE; i++ )){
		done=false 
		state=(0 0)

		while ! $done; do
			local _state_now=${state[@]}

			policy ${state[@]}
			step $action

			get_V_value ${_state_now[@]} V_now
			get_V_value ${state[@]} V_next

			get_gain
			get_td

			update_V_Q ${_state_now[@]}

			echo $action
			echo ${state[@]}
			echo 
		done
	} 
}


show_V(){
	for (( i=0; i<$row_length; i++  )){
		for (( j=0; j<$col_length; j++  )){
			eval echo -n "\${V_line${i}[j]}"
			echo -ne "\t"
		}
		echo 
	}
}


show_Q(){ 
	for (( i=0; i<$row_length; i++  )){ 
		local up_list="" 
		local down_list="" 
		local left_right_list="" 
		local bottom_line=""

		for (( j=0; j<$col_length; j++  )){ 
			eval local _cell=(\${Q_line${i}_col${j}[@]}) 
			up_list+="\t\t${_cell[0]}\t\t|"
			left_right_list+="\t${_cell[2]}\t\t${_cell[3]}\t|"
			down_list+="\t\t${_cell[1]}\t\t|"
			bottom_line+="================================"
		}
		echo -e $up_list 
		echo -e $left_right_list 
		echo -e $down_list 
		echo $bottom_line
	} 
}


policy_idx=0
foo=(DOWN RIGHT RIGHT)


if [ $BASH_SOURCE = $0 ]; then
	init_V
	init_Q 

	learn 
	echo V
	show_V
	echo -e "\n\nQ"
	show_Q
fi
