#/bin/bash

session_name="SETUP"

## start detached tmux session and run command

tmux new-session -d -s ${session_name} './rhel10-workshop.sh all' ; 

## EXAMPLES:
##   how to send additional commands to tmux
##
##     - send 2nd command 'htop -t' ENTER
##
##         tmux send 'htop -t' ENTER;          
##
##     - open (attach) tmux session.          
##                               
##         tmux a;                     
##
