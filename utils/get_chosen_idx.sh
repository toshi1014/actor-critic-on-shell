#!/bin/bash

set -e

readonly RAND_MAX=32767

prob_list=($(cat -))

is_less(){
	bool_fst_thresh_h=`echo "$rand < ${prob_list[0]}" | bc -l`
	bool_snd_thresh_h=`echo "$rand < $snd_thresh_h" | bc -l`
	bool_thd_thresh_h=`echo "$rand < $thd_thresh_h" | bc -l`
}

readonly rand=`echo "scale=5; $RANDOM / $RAND_MAX" | bc -l`
snd_thresh_h=`echo "${prob_list[0]} + ${prob_list[1]}" | bc`
thd_thresh_h=`echo "${prob_list[0]} + ${prob_list[1]} + ${prob_list[2]}" | bc`

is_less $rand

if [ $bool_fst_thresh_h -eq 1 ]; then
	chosen_idx=0
elif [ $bool_snd_thresh_h -eq 1 ]; then
	chosen_idx=1
elif [ $bool_thd_thresh_h -eq 1 ]; then
	chosen_idx=2
else
	chosen_idx=3
fi

echo $chosen_idx