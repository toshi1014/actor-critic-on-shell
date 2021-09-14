#!/bin/bash

set -e

readonly RAND_MAX=32767


raise(){
	local err_msg=$1
	echo error: $err_msg
	return 1
} 


get_softmax(){
	declare -ag prob_list 
	
	local _sum=0

	for (( i=0; i<${#value_list[@]}; i++  )){
		local _x=${value_list[i]}
		_sum=`echo "scale=5; e($_x) + $_sum" | bc -l` 
	}

	for (( i=0; i<${#value_list[@]}; i++  )){
		local _x=${value_list[i]}
		local _v=`echo "scale=5; e($_x)/$_sum" | bc -l` 
		prob_list+=($_v) 
	} 
} 


is_less(){
	local _rand=$1
	bool_fst_thresh_h=`echo "$_rand < ${prob_list[0]}" | bc -l`
	bool_snd_thresh_h=`echo "$_rand < $snd_thresh_h" | bc -l`
	bool_thd_thresh_h=`echo "$_rand < $thd_thresh_h" | bc -l` 
} 


get_chosen_idx(){
	local _rand=`echo "scale=5; $RANDOM / $RAND_MAX" | bc -l`
	snd_thresh_h=`echo "${prob_list[0]} + ${prob_list[1]}" | bc`
	thd_thresh_h=`echo "${prob_list[0]} + ${prob_list[1]} + ${prob_list[2]}" | bc`

	is_less $_rand

	if [ $bool_fst_thresh_h -eq 1 ]; then
		chosen_idx=0
	elif [ $bool_snd_thresh_h -eq 1 ]; then
		chosen_idx=1
	elif [ $bool_thd_thresh_h -eq 1 ]; then
		chosen_idx=2
	else
		chosen_idx=3
	fi 
}
