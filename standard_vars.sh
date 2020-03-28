#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                       Standard Script Global Variables                      *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
# Version: 1.1
#
# Note: GlblDbg and GlblDbgLog options should only be set in this file. This
#       will enable debugging for all standard scripts. For individual script
#       debugging set the Dbg and DbgLog options in the desired scripts.
#
# !!!!                         New coding standard                     !!!!
#		Standard R/W variables are all uppercase preceeded by GST_
#		Standard constants are all uppercase preceeded by GCST_
#		User global R/W variables are all uppercase preceeded by G_
#		User constants are all uppercase preceeded by GC_
#		Local R/W variables can be any case and are preceeded by l_ (Lower case "L")
#		Local constants can be any case and are preceeded by lc_ (Lower case "LC")
#
# You will need a script to change all values reliably.
#
ThisPathNameAbs="`realpath $0`"							# Absolute script pathname
ThisPathAbs=`dirname "$ThisPathNameAbs"`			# Absolute script path
ThisNameAbs=`basename "$ThisPathNameAbs"`			# Absolute script name
																# User script path
ThisPathUser=`echo $(cd \`dirname "${BASH_SOURCE[1]}"\` && pwd)`
ThisNameUser=`basename "${BASH_SOURCE[1]}"`		# User script name
ThisPathNameUser="$ThisPathUser/$ThisNameUser"	# User script pathname
ThisUserName="$USER"										# User name
ThisUserNameReal=`who | awk '{print $1;exit}'`	# Real user name
if [ -z "$ThisUserNameReal" ]; then					# If couldn't get real user 
    ThisUserNameReal="$ThisUserName"				# Use whatever we can
fi
ThisHome=`eval echo "~$ThisUserName"`				# Get user home
ThisHomeReal=`eval echo "~$ThisUserNameReal"`	# Get real user home

#echo "standard_vars.sh: ThisPathNameAbs = $ThisPathNameAbs"
#echo "standard_vars.sh: ThisPathAbs = $ThisPathAbs"
#echo "standard_vars.sh: ThisNameAbs = $ThisNameAbs"
#echo "standard_vars.sh: ThisPathNameUser = $ThisPathNameUser"
#echo "standard_vars.sh: ThisPathUser = $ThisPathUser"
#echo "standard_vars.sh: ThisNameUser = $ThisNameUser"
#echo "standard_vars.sh: ThisUserName = $ThisUserName"
#echo "standard_vars.sh: ThisUserNameReal = $ThisUserNameReal"
#echo "standard_vars.sh: ThisHome = $ThisHome"
#echo "standard_vars.sh: ThisHomeReal = $ThisHomeReal"

ExitStat=0													# Exit status
DelLock=0													# Don't delete lock file
ThisLockFile=""											# Default is no lock file
GlblDbg=0													# 1 to enable global debug
GlblDbgLog=0												# 1 to enable global logging
Dbg=0															# 1 to enable debug output
DbgLog=0														# 1 to enable debug logging
LogCmd="logger"											# System log command
ThisUsage=""												# Script usage message
ThisVersion=""												# Script version
ThisAppName=""												# User friendly script name
CustomCleanupFunc=""										# Custom cleanup function

# Byte Scaling Values
# -------------------
																# Base 10 log for base 10
declare -r SCALE_BASE10_LOG=`echo "l(1000)/l(10)" | bc -l`
																# Base 10 log for base 2
declare -r SCALE_BASE2_LOG=`echo "l(1024)/l(10)" | bc -l`

																# Base 10 scale symbols
declare -r SCALE_SYM_ELM_0=("B" "KB" "MB" "GB" "TB" "PB" "EB" "ZB" "YB")
																# Base 2 scale symbols
declare -r SCALE_SYM_ELM_1=("B" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "ZiB" "YiB")
																# Base mode scale symbols
declare -r SCALE_SYM_ELM_2=("B" "K" "M" "G" "T" "P" "E" "Z" "Y")
																# Scale power lookup
declare -r SCALE_SYM_ELM_3=("0" "3" "6" "9" "12" "15" "18" "21" "24")
declare -r SCALE_SYM_ARY=(								# Scale data array
	SCALE_SYM_ELM_0[@]
	SCALE_SYM_ELM_1[@]
	SCALE_SYM_ELM_2[@]
	SCALE_SYM_ELM_3[@]
)

declare -r SCALE_BASE10_SYMIDX=0						# Base 10 symbol index
declare -r SCALE_BASE2_SYMIDX=1						# Base 2 symbol index
declare -r SCALE_BASEMODE_IDX=2						# Base mode symbol index
declare -r SCALE_PWR_IDX=3								# Scale power index

declare -r SCALE_B=0										# Byte scale
declare -r SCALE_K=1										# KB/KiB scale
declare -r SCALE_M=2										# MB/MiB scale
declare -r SCALE_G=3										# GB/GiB scale
declare -r SCALE_T=4										# TB/TiB scale
declare -r SCALE_P=5										# PB/PiB scale
declare -r SCALE_E=6										# EB/EiB scale
declare -r SCALE_Z=7										# ZB/ZiB scale
declare -r SCALE_Y=8										# YB/YiB scale
declare -r SCALE_MAX="$SCALE_Y"						# Max scale value
declare -r SCALE_AUTO=$((SCALE_MAX+1))				# Auto scale
declare -r SCALE_ARY_ELM_SIZE="$SCALE_AUTO"		# Byte scale element array size
																# Total byte scale array size
declare -r SCALE_ARY_SIZE=$((SCALE_ARY_ELM_SIZE*2))

declare -r SCALE_AUTO_PREC=0							# Auto precision mode
																# Anything above is fixed precision

declare -r SCALE_BASE10_MODE=0						# Base 10 mode
declare -r SCALE_BASE2_MODE=1							# Base 2 mode

declare -r SCALE_BYTES_DSB=0							# Byte display disabled
declare -r SCALE_BYTES_ENB=1							# Byte display enabled

declare -r SCALE_COMMA_DSB=0							# Byte value commas disabled
declare -r SCALE_COMMA_ENB=1							# Byte value commas enabled
