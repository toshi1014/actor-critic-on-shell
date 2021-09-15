#!/bin/bash

set -e
source ./environment.sh

readonly GAMMA
readonly LEARNING_RATE_ACTOR
readonly LEARNING_RATE_CRITIC


init_V(){
	local i j
	for (( i=0; i<$row_length; i++  )){
		for (( j=0; j<$col_length; j++  )){
			eval V_line$i[j]=0
		}
	}
}


init_Q(){
	local i j k
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
	local _state=($1 $2) i
	declare -a _value_list

	for (( i=0; i<${#ACTION_LIST[@]}; i++ )){
		get_Q_now ${_state[@]} $i
		_value_list+=($Q_now)
	}

	local _prob_list=(`echo ${_value_list[@]} | ./utils/get_softmax.sh`)
	local _chosen_idx=`echo ${_prob_list[@]} | ./utils/get_chosen_idx.sh`

	action=${ACTION_LIST[$_chosen_idx]}
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

	local i
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
	local i

	for (( i=0; i<$MAX_EPISODE; i++ )){
		echo -e "\n\tepisode $((i+1))\n"		## i+1: idx to order
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


greedy_policy(){
	local _state=($1 $2)

	get_Q_now ${_state[@]} 0
	local _max_value=$Q_now
	local _arg_max=0

	for (( i=0; i<${#ACTION_LIST[@]}; i++ )){
		get_Q_now ${_state[@]} $i
		if [ `echo "scale=5; $Q_now > $_max_value" | bc -l` -eq 1 ]; then
			_max_value=$Q_now
			_arg_max=$i
		fi
	}

	action=${ACTION_LIST[$_arg_max]}
}


best_move(){
	echo -e "\n\n\tbest move\n"
	done=false
	state=(0 0)
	local _sum_reward=0

	while ! $done; do
		local _state_now=${state[@]}

		greedy_policy ${state[@]}
		step $action

		_sum_reward=`echo "scale=5; $reward + $_sum_reward" | bc -l`

		echo $action
		echo ${state[@]}
		echo
	done

	echo total_reward: $_sum_reward
}


show_V(){
	local i j

	for (( i=0; i<$row_length; i++  )){
		for (( j=0; j<$col_length; j++  )){
			eval echo -n "\${V_line${i}[j]}"
			echo -ne "\t"
		}
		echo
	}
}


show_Q(){
	local i j

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


if [ $BASH_SOURCE = $0 ]; then
	readonly MAX_EPISODE=1

	init_V
	init_Q

	learn
	echo V
	show_V
	echo -e "\n\nQ"
	show_Q
fi