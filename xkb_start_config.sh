#!/bin/bash
cd "/home/steve/Projects/keyboard/BigBagKbdTrixXKB"
sleep 2
./setxkb.sh > ~/.bigbag_xkb.log 2>&1
xkbset m
xkbset exp =m
