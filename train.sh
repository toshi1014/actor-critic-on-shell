#!/bin/bash

set -e

source ./actor_critic_agent.sh

readonly MAX_EPISODE

init_V
init_Q

learn $MAX_EPISODE

echo V
show_V
echo -e "\n\nQ"
show_Q