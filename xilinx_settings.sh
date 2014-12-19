#!/bin/bash

# Fixed settings file for Xilinx ISE Development tools
# May need to update XILINX_DIR and SETTINGS_FILE based upon your own setup
# This probably wont work for all shells, and it isn't exactly an elegant 
# solution, but it does make things work on my zsh setup, so I'm happy.
# Note that the commented code near the bottom might help make things a 
# little nicer/cleaner, though I was unable to get the for loop just right
# for zsh to accept it, I'll leave it there in case other wish to give it a go.

XILINX_DIR="/opt/Xilinx/14.7/ISE_DS"
SETTINGS_FILE=.settings64.sh

. "$XILINX_DIR/common/$SETTINGS_FILE" "$XILINX_DIR/common"
. "$XILINX_DIR/EDK/$SETTINGS_FILE" "$XILINX_DIR/EDK"
. "$XILINX_DIR/PlanAhead/$SETTINGS_FILE" "$XILINX_DIR/PlanAhead"
. "$XILINX_DIR/ISE/$SETTINGS_FILE" "$XILINX_DIR/ISE"

#settings_locations=""
#settings_locations="$settings_locations common"
#settings_locations="$settings_locations EDK"
#settings_locations="$settings_locations PlanAhead"
#settings_locations="$settings_locations ISE"

#for i in $settings_locations
#do
#	curr_dir="$XILINX_DIR/$i"
#	curr_file="$curr_dir/$SETTINGS_FILE"
#	echo . $curr_file $curr_dir
#	#. "$curr_file" "$curr_dir"
#done
#
