#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                           Standard Script Functions                         *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
# Version: 1.3
#
#*******************************************************************************
#*                            Debug Print Function                             *
#*******************************************************************************
#
# Function: Outputs debug message to stdout and system log.
#
# Global Variables:
#   Dbg     1 enables debug message output.
#   DbgLog  1 enables debug message logging.
#
# Input:
#   Arg1  Debug message.
#	 Arg2  Optional 0 = Interpret backslash chars, 1 = Don't.
#
# Output: No variables passed.
#
function DbgPrint ()
{
	local l_NoE=0
																# If debug output enabled
   if [ $Dbg -eq 1 ] || [ $GlblDbg -eq 1 ] || [ $DbgLog -eq 1 ] || [ $GlblDbgLog -eq 1 ]; then
		if [ $# -eq 2 ] && [ $2 -eq 1 ]; then
			l_NoE=1
		fi
																# Create message
      local DbgMsg="[$ThisPathNameUser] DEBUG: $1"
		if [ $Dbg -eq 1 ] || [ $GlblDbg -eq 1 ]; then
			if [ $l_NoE -eq 0 ]; then
				echo -e "$DbgMsg"							# Output message
			else
				echo "$DbgMsg"								# Output message
			fi
		fi
																# If debug logging enabled
      if [ $DbgLog -eq 1 ] || [ $GlblDbgLog -eq 1 ]; then
         $LogCmd "$DbgMsg"								# Log message
      fi
   fi
}

#*******************************************************************************
#*                           Information Print Function                        *
#*******************************************************************************
#
# Function: Outputs warning message to stdout and system log.
#
# Global Variables:
#   Dbg     1 enables debug message output.
#   DbgLog  1 enables debug message logging.
#
# Input:
#   Arg1  Information message.
#
# Output: No variables passed.
#
function InfoPrint ()
{						# Create message
   local InfoMsg="INFORMATION: $1"
   echo -e "$InfoMsg"				# Output message
						# If debug logging enabled
   if [ $DbgLog -eq 1 ] || [ $GlblDbgLog -eq 1 ]; then
      InfoMsg="[$ThisPathNameUser] $InfoMsg"	# Create log message
      $LogCmd "$InfoMsg"			# Log message
   fi
}

#*******************************************************************************
#*                           Warning Print Function                            *
#*******************************************************************************
#
# Function: Outputs warning message to stdout and system log.
#
# Global Variables:
#   Dbg     1 enables debug message output.
#   DbgLog  1 enables debug message logging.
#
# Input:
#   Arg1  Warning message.
#
# Output: No variables passed.
#
function WarnPrint ()
{
   local WarnMsg="WARNING: $1"			# Create message
   echo -e "$WarnMsg"				# Output message
						# If debug logging enabled
   if [ $DbgLog -eq 1 ] || [ $GlblDbgLog -eq 1 ]; then
      WarnMsg="[$ThisPathNameUser] $WarnMsg"	# Create log message
      $LogCmd "$WarnMsg"			# Log message
   fi
}

#*******************************************************************************
#*                             Error Print Function                            *
#*******************************************************************************
#
# Function: Outputs error message to stdout and system log.
#
# Global Variables:
#   Dbg     1 enables debug message output.
#   DbgLog  1 enables debug message logging.
#
# Input:
#   Arg1  Error message.
#
# Output: No variables passed.
#
function ErrorPrint ()
{
   local ErrMsg="ERROR: $1"			# Create message
   echo -e "$ErrMsg"				# Output message
						# If debug logging enabled
   if [ $DbgLog -eq 1 ] || [ $GlblDbgLog -eq 1 ]; then
      ErrMsg="[$ThisPathNameUser] $ErrMsg"		# Create log message
      $LogCmd "$ErrMsg"				# Log error message
   fi
}

#*******************************************************************************
#*                             Error Exit Function                             *
#*******************************************************************************
#
# Function: Outputs error message to stdout and system log and does CleanUpExit.
#
# Global Variables:
#   Dbg     1 enables debug message output.
#   DbgLog  1 enables debug message logging.
#
# Input:
#   Arg1  Debug message.
#   Arg2  Optional exit status. If empty exits with status 1.
#
# Output: No variables passed.
#
function ErrorExit ()
{
	local l_ExitStat=0

   ErrorPrint "$1"

   if [ -z ${2+x} ]; then			# If no error code
      l_ExitStat=1					# Default error code is 1
   else
      l_ExitStat=$2					# Otherwise use user error code
   fi

   CleanUpExit $l_ExitStat
}

#*******************************************************************************
#*                            Check If Function Exists                         *
#*******************************************************************************
#
# Function: Cleans up system on exit.
#
# Input:
#   Arg1 = Function name.
#
# Output: No variables passed.
#
# Return Status:
#   0		No error
#   1		Not a function
#
FuncExists()
{
	type -t $1 | grep -q 'function'
}

#*******************************************************************************
#*                         Get Absolute Path of Directory                      *
#*******************************************************************************
#
# Function: Returns the absolute path of a possibly linked directory.
#
# Input:
#   Arg1 = Directory.
#   Arg2 = Return variable name (passed without $)
#
# Output: No variables passed.
#
# Return Status:
#   0		Absolute path found
#   1		Directory doesn't exist
#
GetAbsPath()
{
	local lclDir="$1"
	local -n lclAbsPath="$2"
	local l_ExitStat=1

	#DbgPrint "GetAbsPath: Entered with lclDir=\"$lclDir\", lclAbsPath return variable name=\"$2\""

	lclAbsPath=""
	if [ -d "$lclDir" ]; then					# If dir exists
		lclAbsPath=`readlink -f "$lclDir"`
		l_ExitStat=0
		#DbgPrint "GetAbsPath: Absolute path for \"$lclDir\" is \"$lclAbsPath\""
	fi
    #DbgPrint "GetAbsPath: Exiting"

	return "$l_ExitStat"
}

#*******************************************************************************
#*                             Ask Yes/No Question                             *
#*******************************************************************************
#
# Function: Asks yes/no question and returns "y" or "n"
#
# Input:
#   Arg1 = Output question
#   Arg2 = Return variable name (passed without $)
#
# Output:
#   Arg2 return variable contains "y" or "n"
#

function AskYesNo ()
{
   local __TmpMsg="$1"
   local __ReturnVal="$2"
   local __Input=''
   local __Answer=''
   local __TmpFlag=1

   while [ $__TmpFlag -eq 1 ]; do
      read -p "$__TmpMsg (y/n)? " __Input	# Ask question
      case "$__Input" in 
         y|Y)					# Yes
            __Answer="y"			# Always reurn lowercase
            __TmpFlag=0				# Stop loop
         ;;

         n|N)					# No
            __Answer="n"			# Always reurn lowercase
            __TmpFlag=0				# Stop loop
         ;;

         *)					# Invalid response
            echo -e "'$__Input' is an invalid response.\n"
         ;;
      esac
   done
   eval $__ReturnVal="'$__Answer'"
}

#*******************************************************************************
#*                      Create Space Padded Centered String                    *
#*******************************************************************************
#
# Function: Creates a center justified space padded string. 
#
# Input:
#   Arg1 = String to be centered
#   Arg2 = Total string length
#   Arg3 = String return variable name
#
# Output:
#   Arg3 return variable contains centered string
#
function CenterStr ()
{
   local __LclCntrStrIn="$1"
   local __LclCntrTotLen="$2"
   local __LclCntrStrRet="$3"
   local __LclCntrStr=""
   local StrLen=0
   local StrPad=0
   local StrPadL=0
   local StrPadR=0

   StrLen=`expr length "$__LclCntrStrIn"`	# Get string length
   StrPad=$((__LclCntrTotLen-StrLen))		# Get total pad length
   StrPadL=$((StrPad/2))			# Get left pad length
   StrPadR=$((StrPad-StrPadL))			# Get right pad length
					
   __LclCntrStr=`printf '%*s' $StrPadL`		# Add left pad
   __LclCntrStr="$__LclCntrStr$__LclCntrStrIn"	# Add string
						# Add right pad
   __LclCntrStr="$__LclCntrStr"`printf '%*s' $StrPadR`

   eval $__LclCntrStrRet="'$__LclCntrStr'"
}

#*******************************************************************************
#*                         Create Left Justified String                        *
#*******************************************************************************
#
# Function: Creates a left justified space padded string. 
#
# Input:
#   Arg1 = String to be left justified
#   Arg2 = Total string length
#   Arg3 = String return variable name
#
# Output:
#   Arg3 return variable contains centered string
#
function LeftStr ()
{
   local __LclLeftStrIn="$1"
   local __LclLeftTotLen="$2"
   local __LclLeftStrRet="$3"
   local __LclLeftStr=""
   local StrLen=0
   local StrPad=0

   StrLen=`expr length "$__LclLeftStrIn"`	# Get string length
   StrPad=$((__LclLeftTotLen-StrLen))		# Get total pad length
														# Add right pad
   __LclLeftStr="$__LclLeftStrIn"`printf '%*s' $StrPad`

   eval $__LclLeftStrRet="'$__LclLeftStr'"
}


#*******************************************************************************
#*                        Create Right Justified String                        *
#*******************************************************************************
#
# Function: Creates a right justified space padded string. 
#
# Input:
#   Arg1 = String to be right justified
#   Arg2 = Total string length
#   Arg3 = String return variable name
#
# Output:
#   Arg3 return variable contains centered string
#
function RightStr ()
{
   local __LclRghtStrIn="$1"
   local __LclRghtTotLen="$2"
   local __LclRghtStrRet="$3"
   local __LclRghtStr=""
   local StrLen=0
   local StrPad=0

   StrLen=`expr length "$__LclRghtStrIn"`			# Get string length
   StrPad=$((__LclRghtTotLen-StrLen))				# Get total pad length

   __LclRghtStr=`printf '%*s' $StrPad`				# Add left pad
   __LclRghtStr="$__LclRghtStr$__LclRghtStrIn"	# Add string

   eval $__LclRghtStrRet="'$__LclRghtStr'"
}

#*******************************************************************************
#*                           Create Character String                           *
#*******************************************************************************
#
# Function: Creates a string with the specified character and length. 
#
# Input:
#   Arg1 = Character
#   Arg2 = String length
#   Arg3 = String return variable name
#
# Output:
#   Arg3 = Return variable contains character string.
#
function CharStr ()
{
	local __LclCharIn="$1"
	local __LclCharLen="$2"
	local __LclCharStrRet="$3"
   local __LclCharStr=""

	__LclCharStr=$(printf "%-${__LclCharLen}s" "$__LclCharIn")
	__LclCharStr="${__LclCharStr// /$__LclCharIn}"

   eval $__LclCharStrRet="'$__LclCharStr'"
}

#*******************************************************************************
#*            Create Left Justified Space Padded Underline String              *
#*******************************************************************************
#
# Function: Creates a left justified space padded underline string. 
#
# Input:
#   Arg1 = Underline length.
#   Arg2 = Total string length.
#   Arg3 = String return variable name.
#
# Output:
#   Arg3 = Return variable contains underline string.
#
function UnderlinePadLeft ()
{
   local __LclUndrLLen="$1"
   local __LclUndrLTotLen="$2"
   local __LclUndrLStrRet="$3"
   local __LclUndrLStr=""

   __LclUndrLStr=`printf '%*s' $__LclUndrLLen | tr ' ' '-'`
   __LclUndrLStr="$__LclUndrLStr"`printf '%*s' $((__LclUndrLTotLen-__LclUndrLLen))`

   eval $__LclUndrLStrRet="'$__LclUndrLStr'"
}

#*******************************************************************************
#*                             Check for Integer Value                         *
#*******************************************************************************
#
# Function: Checks a value to see if it's an integer. 
#
# Input:
#   Arg1 = Value.
#
# Output:
#   No parameters passed.
#
# Return Status:
#   0 = Is decimal number
#   1 = Is not decimal number
#

function IsInteger ()
{
	local LclExitStat=0

	case ${1#[-+]} in
		*[!0-9]* | '')
# echo "It's not an integer: \"$1\""
			LclExitStat=1
		;;

		*)
		;;
	esac
	return "$LclExitStat"
}

#*******************************************************************************
#*                  Check for Positive or Negative Integer Value               *
#*******************************************************************************
#
# Function: Checks a value to see if it's an integer. 
#
# Input:
#   Arg1 = Value.
#
# Output:
#   No parameters passed.
#
# Return Status:
#   0 = Is positive integer
#   1 = Is negative integer
#   2 = Is not decimal number
#

function IsPosNeg ()
{
	local LclExitStat=0

   if IsInteger "$1"; then								# If val is integer
# echo "It's an integer: \"$1\""
		if [ "${1:0:1}" = "-" ]; then					# If it's negative
# echo "It's a negative integer: \"$1\""
			LclExitStat=1									# Set negative integer
		fi
	else
# echo "It's not an integer: \"$1\""
		LclExitStat=2										# Set not an integer
	fi
# echo "Returning LclExitStat: $LclExitStat"
	return "$LclExitStat"
}

#*******************************************************************************
#*                  Convert Bytes to Fixed Scale and Symbol                    *
#*******************************************************************************
#
# Function: Converts a byte value into a specific base 10/base 2 scale value and
#           symbol. 
#
# Input:
#   Arg1 = Byte value.
#   Arg2 = Decimal precision. If SCALE_AUTO_PREC it's automatically calculated.
#   Arg3 = Decimal places.
#   Arg4 = Base mode. SCALE_BASE10_MODE = Base 10, SCALE_BASE2_MODE = Base 2.
#   Arg5 = Scale value. See SCALE_SYM_ARY for values.
#   Arg6 = Comma enable. SCALE_COMMA_ENB = Enable, SCALE_COMMA_DSB = disable.
#   Arg7 = Value string return variable name.
#   Arg8 = Symbol string return variable name.
#
# Output:
#   Arg7 = Return variable contains value string.
#   Arg8 = Return variable contains symbol string.
#
# Return Status:
#   0 = No error.
#   1 = Invalid byte value
#   2 = Invalid precision value
#   3 = Invalid decimal places value
#   4 = Invalid base mode value
#   5 = Invalid scale value
#   6 = Invalid comma enable
#
function FormatBytesFixed ()
{
   local LclBytes="$1"									# Byte value
   local LclPrec="$2"									# Decimal precision
   local LclPlaces="$3"									# Decimal places returned		
   local LclBaseMode="$4"								# Base 2/10 mode
	local LclScale="$5"									# Scale value
	local LclCommaEnb="$6"								# Allow commas in bytes flag
   local __LclFBFixedValRet="$7"						# Value return variable name
   local __LclFBFixedSymRet="$8"						# Symbol return variable name
   local __LclFBFixedVal=""							# Local value return string
   local __LclFBFixedSym=""							# Local symbol return string
   local	LclBytesLog=0									# Bytes log value
   local LclDivVal=0										# Scale value
   local LclBase=0										# Base value
   local LclPwr=0											# Power value
   local LclExitStat=0									# Exit status
	local	LclBaseLog=0									

# ----------------
# Verify Arguments
# ----------------

   if ! IsPosNeg "$LclBytes"; then					# If invalid byte value
		LclExitStat=1
		__LclFBFixedVal="Invalid byte value"

   elif ! IsPosNeg "$LclPrec"; then					# If invalid precision
		LclExitStat=2
		__LclFBFixedVal="Invalid precision value"

   elif ! IsPosNeg "$LclPlaces"; then				# If invalid decimal places
		LclExitStat=3
		__LclFBFixedVal="Invalid decimal places value"
																# If invalid base mode
   elif ! IsPosNeg "$LclBase" || [[ "$LclBase" -ne "$SCALE_BASE10_MODE" && "$LclBase" -ne "$SCALE_BASE2_MODE" ]] ; then
		LclExitStat=4
		__LclFBFixedVal="Invalid base value"
																# If invalid scale value
   elif ! IsPosNeg "$LclScale" || [[ ! "$LclScale" -lt "$SCALE_ARY_ELM_SIZE" ]] ; then
		LclExitStat=5
		__LclFBFixedVal="Invalid scale value"
																# If invalid comma enable
   elif ! IsPosNeg "$LclCommaEnb" || [[ "$LclCommaEnb" -ne "$SCALE_COMMA_ENB" && "$LclCommaEnb" -ne "$SCALE_COMMA_DSB" ]] ; then
		LclExitStat=6
		__LclFBFixedVal="Invalid comma enable value"
   fi

# -------------
# Convert Value
# -------------
	LclBytes="${LclBytes#[+]}"							# Strip possible +
	if [[ $LclExitStat -eq 0 ]]; then				# If arguments are okay
																# If base 10 mode
		if [[ $LclBaseMode -eq "$SCALE_BASE10_MODE" ]]; then
			LclPwr=$(($LclScale * 3))					# Calc power multiplier (3/6/9 ...)
#echo "LclPwr = LclScale($LclScale) * 3: $LclPwr"
			LclBase=10
		else													# If base 2
			LclPwr=$(($LclScale * 10))					# Calc power multiplier (10/20/30 ...)
#echo "LclPwr = LclScale($LclScale) * 10: $LclPwr"
			LclBase=2
		fi
																# Create byte divider
		LclDivVal=`echo "$LclBase^$LclPwr" | bc -l`

#echo "LclDivVal = LclBase($LclBase) ^ LclPwr($LclPwr): $LclDivVal"
																# If auto precision
		if [[ "$LclPrec" -eq "$SCALE_AUTO_PREC" ]]; then
#echo "Setting auto precision. LclPrec before: $LclPrec"
			LclPrec="$(((Scale*3)*2))"
#echo "Setting auto precision. LclPrec after: $LclPrec"
		fi
																# If not 0 bytes and not byte scale
		if [[ "$LclBytes" -gt 0 ]] && [[ $LclScale -ne "$SCALE_B" ]]; then
																# Divide to calc value
			__LclFBFixedVal=`awk -v b=$LclBytes -v s=$LclDivVal -v p=$LclPrec 'BEGIN { printf "%0.*f\n", p, b / s }'`
#echo "__LclFBFixedVal after divide, before decimal places set = $__LclFBFixedVal"
		else													# If 0 or byte scale don't divide
			__LclFBFixedVal=`awk -v b=$LclBytes -v p=$LclPrec 'BEGIN { printf "%0.*f\n", p, b }'`
#echo "__LclFBFixedVal no divide, before decimal places set = $__LclFBFixedVal"
		fi
																# If not byte scale or 0 dec places
		if [[ $LclScale -ne "$SCALE_B" ]] && [[ $LclPlaces -ne "0" ]]; then
																# Truncate to specified dec places
			__LclFBFixedVal=`sed -re "s/([0-9]+\.[0-9]{$LclPlaces})[0-9]+/\1/g" <<< $__LclFBFixedVal`
		else													# Otherwise remove all dec places
			__LclFBFixedVal="${__LclFBFixedVal%.*}"
		fi
#echo "__LclFBFixedVal after decimal places set = $__LclFBFixedVal"
																# Get symbol from array
		__LclFBFixedSym="${!SCALE_SYM_ARY[$LclBaseMode]:$LclScale:1}"
	fi
																# If byte scale and enable commas flag
	if [ "$LclScale" -eq "$SCALE_B" ] && [ "$LclCommaEnb" -eq "$SCALE_COMMA_ENB" ]; then
#echo "__LclFBFixedVal after comma add places set = $__LclFBFixedVal"
																# Add commas
		__LclFBFixedVal="$(printf "%'d" $__LclFBFixedVal)"
	fi

#echo "Exit __LclFBFixedVal = $__LclFBFixedVal"
#echo "Exit __LclFBFixedSym = $__LclFBFixedSym"
																# Return value
   eval $__LclFBFixedValRet="'$__LclFBFixedVal'"
																# Return symbol
   eval $__LclFBFixedSymRet="'$__LclFBFixedSym'"
	return "$LclExitStat"								# Return status
}

#*******************************************************************************
#*                   Convert Bytes to Auto Scale and Symbol                    *
#*******************************************************************************
#
# Function: Converts a byte value into the specified base 10/base 2 optimum
#           value and symbol. 
#
# Input:
#   Arg1 = Byte value.
#   Arg2 = Decimal precision. If SCALE_AUTO_PREC it's automatically calculated.
#   Arg3 = Decimal places.
#   Arg4 = Base mode. SCALE_BASE10_MODE = Base 10, SCALE_BASE2_MODE = Base 2.
#   Arg5 = Byte scale enable. SCALE_BYTES_DSB = Enable,
#          SCALE_BYTES_DSB = Disable
#   Arg6 = Value string return variable name.
#   Arg7 = Symbol string return variable name.
#
# Output:
#   Arg6 = Return variable contains value string.
#   Arg7 = Return variable contains symbol string.
#
# Return Status:
#   0 = No error.
#   1 = Invalid byte value
#   2 = Invalid precision value
#   3 = Invalid decimal places value
#   4 = Invalid base value
#   5 = Invalid enable bytes flag value
#   6 = Invalid comma enable
#
function FormatBytesAuto ()
{
   local LclBytes="$1"									# Byte value
   local LclPrec="$2"									# Decimal precision
   local LclPlaces="$3"									# Decimal places		
   local LclBaseMode="$4"								# Base mode
   local LclByteSEnb="$5"								# Byte scale enable flag
   local LclCommaEnb="$6"								# Comma enable flag
   local __LclFBAutoValRet="$7"						# Value return variable name
   local __LclFBAutoSymRet="$8"						# Symbol return variable name
   local __LclFBAutoVal=""								# Local value return string
   local __LclFBAutoSym=""								# Local symbol return string
   local	LclBytesLog=0									# Bytes log value
   local LclDivVal=0										# Scale value
   local LclSymIdx=0										# Scale index
   local LclPwr=0											# Power value
   local LclExitStat=0									# Exit status
	local	LclBaseLog=0									

#echo "Entry LclBytes = $LclBytes"
#echo "Entry LclPrec = $LclPrec"
#echo "Entry LclPlaces = $LclPlaces"
#echo "Entry LclBaseMode = $LclBaseMode"
#echo "Entry LclByteSEnb = $LclByteSEnb"
#echo "Entry __LclFBAutoValRet = $__LclFBAutoValRet"
#echo "Entry __LclFBAutoSymRet = $__LclFBAutoSymRet"


# ----------------
# Verify Arguments
# ----------------

   if ! IsPosNeg "$LclBytes"; then					# If invalid byte value
		LclExitStat=1
		__LclFBAutoVal="Invalid byte value"

   elif ! IsPosNeg "$LclPrec"; then					# If invalid precision value
		LclExitStat=2
		__LclFBAutoVal="Invalid precision value"

   elif ! IsPosNeg "$LclPlaces"; then				# If invalid decimal places
		LclExitStat=3
		__LclFBFixedVal="Invalid decimal places value"
																# If invalid base value
   elif ! IsPosNeg "$LclBaseMode" || [[ "$LclBaseMode" -ne "$SCALE_BASE10_MODE" && "$LclBaseMode" -ne "$SCALE_BASE2_MODE" ]] ; then
		LclExitStat=4
		__LclFBAutoVal="Invalid base value"
 																# If invalid byte scale enable value
   elif ! IsPosNeg "$LclByteSEnb" || [[ "$LclByteSEnb" -ne "$SCALE_BYTES_DSB" && "$LclByteSEnb" -ne "$SCALE_BYTES_ENB" ]] ; then
		LclExitStat=5
		__LclFBAutoVal="Invalid enable bytes flag value"
																# If invalid comma enable
   elif ! IsPosNeg "$LclCommaEnb" || [[ "$LclCommaEnb" -ne "$SCALE_COMMA_ENB" && "$LclCommaEnb" -ne "$SCALE_COMMA_DSB" ]] ; then
		LclExitStat=6
		__LclFBFixedVal="Invalid comma enable value"
  fi

# -------------
# Convert Value
# -------------

	LclBytes="${LclBytes#[+]}"							# Strip possible +
	if [[ $LclExitStat -eq 0 ]]; then				# If arguments are okay
		if [[ $LclBytes -gt 0 ]]; then				# If not 0 bytes
																# If base 10
			if [[ $LclBaseMode -eq "$SCALE_BASE10_MODE" ]]; then
				LclBaseLog=$SCALE_BASE10_LOG			# Load base 10 log
			else												# If base 2
				LclBaseLog=$SCALE_BASE2_LOG			# Load base 2 log
			fi
																# Get base 10 log for bytes
			LclBytesLog=`echo "l($LclBytes)/l(10)" | bc -l`
																# Get scale index float
			LclSymIdx=`awk -v b=$LclBytesLog -v s=$LclBaseLog 'BEGIN { printf "%0f\n", b / s }'`
			LclSymIdx=${LclSymIdx%.*}					# Get scale index integer
																# If Byte scale and disable byte scale
			if [ "$LclSymIdx" -eq "$SCALE_B" ] && [ "$LclByteSEnb" -eq "$SCALE_BYTES_DSB" ]; then
				LclSymIdx="$SCALE_K"						# Set to KB/KiB
			fi
		else													# If 0 bytes
																# If byte scale disabled
			if [ $LclByteSEnb -eq "$SCALE_BYTES_DSB" ]; then
				LclSymIdx="$SCALE_K"						# Set KB/KiB scale
			else
				LclSymIdx="$SCALE_B"						# Otherwise byte scale
			fi
		fi
		
		FormatBytesFixed "$LclBytes" "$LclPrec" "$LclPlaces" "$LclBaseMode" "$LclSymIdx" "$LclCommaEnb" __LclFBAutoVal __LclFBAutoSym
	fi

#echo "Exit __LclFBAutoVal = $__LclFBAutoVal"
#echo "Exit __LclFBAutoSym = $__LclFBAutoSym"

   eval $__LclFBAutoValRet="'$__LclFBAutoVal'"	# Return value
   eval $__LclFBAutoSymRet="'$__LclFBAutoSym'"	# Return symbol
	return "$LclExitStat"								# Return status
}

#*******************************************************************************
#*                            Verify Directory Exists                          *
#*******************************************************************************
#
# Input:
#	Arg 1 = Directory path
#	Arg 2 = Return variable name (passed without $)
#
# Output:
#   Arg2 Returns error message if fail.
#   Return Status -
#		0 = Directory exists
#		1 = Directory doesn't exist
#		2 = File detected instead of directory
#
function VerifyDirExists()
{
   local __LclDir="$1"
   local __ReturnVal=$2
   local __LclReturnMsg='Directory exists: \"$__LclDir\"'
   local __LclExitStat=0

   #DbgPrint "Entered VerifyDirExists with directory \"$__LclDir\"."

   if [ ! -e $__LclDir ]; then				# If nothing exists
      __LclReturnMsg="Directory doesn'\''t exist: \"$__LclDir\""
		__LclExitStat=1
	elif [ ! -d $__LclDir ]; then			# If it exists but it's a file
		__LclReturnMsg="File detected instead of directory: \"$__LclDir\""
		__LclExitStat=2
   fi

   eval $__ReturnVal="'$__LclReturnMsg'"

   #DbgPrint "Exiting VerifyDirExists."
	return $__LclExitStat
}

#*******************************************************************************
#*                             Clean Up Exit Function                          *
#*******************************************************************************
#
# Function: Cleans up system on exit.
#
# Input:
#	Arg1	Exit status.
#	Arg2  Optional custom cleanup function name. It must be or begin with
#			"SVCustom" or it will not be executed
#
# Output:
#	Not variables passed.
#
# Exit Status:
#	Exits script with exit status.
#
function CleanUpExit ()
{
	local l_ExitStat=$1
	local l_CustomCleanupFunc="$2"

   DbgPrint "Executing CleanUpExit."
																# If we have a custom function
	DbgPrint "Custom cleanup function = \"$l_CustomCleanupFunc\"."

   if [[ ! -z "${l_CustomCleanupFunc// }" ]]; then
		DbgPrint "Detected custom cleanup function \"$l_CustomCleanupFunc\"."
																# If valid name
		if [[ "$l_CustomCleanupFunc" == SVCustom* ]]; then
			if FuncExists $l_CustomCleanupFunc; then	# If function exists
				DbgPrint "Executing custom cleanup function \"$l_CustomCleanupFunc\"."
				$l_CustomCleanupFunc						# Execute function
			else
				ErrorPrint "Custom cleanup function doesn't exist \"$l_CustomCleanupFunc\"."
			fi
		else													# If invalid name
			ErrorPrint "Invalid custom cleanup function name, must start with \"SVCustom\": \"$l_CustomCleanupFunc\"."
		fi
	fi

   if [ "$DelLock" -eq 1 ]; then						# If we have lock file
      DbgPrint "Deleting lock '$ThisLockFile'"
      rm "$ThisLockFile"								# Delete it
   fi
   DbgPrint "Exiting after clean up, Status = '$l_ExitStat'."
   exit $l_ExitStat
}

#*******************************************************************************
#*                             SIGHUP Trap Function                            *
#*******************************************************************************
#
# Function: Outputs debug message and cleans up system on SIGHUP
#
# Input: No variables passed.
#
# Output: No variables passed.
#
function TrapSIGHUP ()
{
   DbgPrint "Executing SIGHUP trap and clean up."
   CleanUpExit
}

#*******************************************************************************
#*                             SIGINT Trap Function                            *
#*******************************************************************************
#
# Function: Outputs debug message and cleans up system on SIGINT
#
# Input: No variables passed.
#
# Output: No variables passed.
#
function TrapSIGINT ()
{
   DbgPrint "Executing SIGINT trap and clean up."
   ExitStat=1
   CleanUpExit
}

#*******************************************************************************
#*                             SIGTERM Trap Function                           *
#*******************************************************************************
#
# Function: Outputs debug message and cleans up system on SIGHUP
#
# Input: No variables passed.
#
# Output: No variables passed.
#
function TrapSIGTERM ()
{
   DbgPrint "Executing SIGTERM trap and clean up."
   CleanUpExit
}

#*******************************************************************************
#*                             SIGKILL Trap Function                           *
#*******************************************************************************
#
# Function: Outputs debug message and cleans up system on SIGHUP
#
# Input: No variables passed.
#
# Output: No variables passed.
#
function TrapSIGKILL ()
{
   DbgPrint "Executing SIGKILL trap and clean up."
   CleanUpExit
}
