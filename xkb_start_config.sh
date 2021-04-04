#!/bin/bash
cd "/home/steve/Projects/keyboard/BigBagKbdTrixXKB"
sleep 1
./setxkb.sh > ~/.bigbag_xkb.log 2>&1
xkbset m # sticky -twokey latchlock
