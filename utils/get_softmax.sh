#!/bin/bash

set -e

value_list=($(cat -))

declare -a prob_list
sum=0

for (( i=0; i<${#value_list[@]}; i++ )){
	x=${value_list[i]}
	sum=`echo "scale=5; e($x) + $sum" | bc -l`
}

for (( i=0; i<${#value_list[@]}; i++ )){
	x=${value_list[i]}
	v=`echo "scale=5; e($x) / $sum" | bc -l`
	prob_list+=($v)
}

echo ${prob_list[@]}