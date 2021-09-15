#!/bin/bash

set -e

source ./actor_critic_agent.sh

readonly DEFAULT_MAX_VALUE


usage(){
    echo -e "" >&2
    echo -e "Usage: bash train.sh <MAX_EPISODE>" >&2
    echo -e "\n\tdefault MAX_EPISODE is $DEFAULT_MAX_VALUE" >&2
    echo >&2

    exit 1
}


case $# in
    0 ) readonly MAX_EPISODE=$DEFAULT_MAX_VALUE;;
    1 ) readonly MAX_EPISODE=$1;;
    * ) usage;;
esac

init_V
init_Q

learn

echo V
show_V
echo -e "\n\nQ"
show_Q

best_move