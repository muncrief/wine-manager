#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                                Token Parser                                 *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
# Function:
#   Parses an input array according to a parse instruction array using indirect
#   variable referencing. The input array is a one dimensional array consisting
#   of tokens followed by possible arguments.
#
#   The parse array must be in a specific format. It's a two dimensional array
#   with each element consisting of a Token string, Found Flag variable name,
#   Number of minimum arguments integer, Number of maximum arguments integer,
#   and possible Argument variable name. If maximum arguments is greater than 1
#   then the Argument variable name must be for an array. When a Token is found
#   its corresponding Found Flag is set to 1 and any Argument variable is
#   written. Element Found Flag and Argument variables are passed by name
#   without the '$' prefix. Element array Argument variables are passed
#   without the [@] suffix. Parse array elements are passed by name
#   without the '$' prefix, but with the [@] suffix.
#
#      Format: Token, Found Flag var name, Min args, Max args, Arg var name
#
#      TokElm_0=("Tok0" "Tok0F_VarName" "0" "0")
#      TokElm_1=("Tok1" "Tok1F_VarName" "1" "1" "Tok1_VarName")
#      TokElm_2=("Tok2" "Tok2F_VarName" "2" "3" "Tok2_VarName")
#      TokElm_3=("Tok3" "Tok2F_VarName" "0" "2" "Tok3_VarName")
#
#      ParseAry=(
#         TokElm_0[@]
#         TokElm_1[@]
#         TokElm_2[@]
#         TokElm_3[@]
#      )
#
# Input:
#   Arg1  Input array variable name.
#   Arg2  Parse array input/return variable name.
#   Arg3  Number of tokens found return variable name.
#   Arg4  Last Input Array index return variable name.
#   Arg5  Last Parse Array index return variable name.
#   Arg6  Last Argument index return variable name.
#
# Output:
#   Arg2  Parse array is filled with parsed values.
#   Arg3  Variable contains number of tokens found.
#   Arg4  Variable contains last Input Array index. If an input Token error
#         occurs this will point to the unfound token.
#   Arg5  Variable contains last Parse Array index. This is always the index of
#         the last processed Parse Array element.
#   Arg6  Variable contains last Argument index. If an Argument error occurs
#         this will point to the problem argument.
#
# Return Status:
#   TP_ERR_NONE					# No error
#   TP_ERR_NUM_ARGS				# Incorrect number of input arguments
#   TP_ERR_NO_ARY_INPUT			# No input array variable name
#   TP_ERR_NO_ARY_PARSE			# No parse array variable name
#   TP_ERR_NO_VAR_NUMTOKS		# No number of tokens found variable name
#   TP_ERR_NO_VAR_LAST_II		# No Last Input Array Index variable name
#   TP_ERR_NO_VAR_LAST_PI		# No Last Parse Array Index variable name
#   TP_ERR_NO_VAR_LAST_AI		# No Last Argument Index variable name
#   TP_ERR_NO_VAR_TOKE_FND		# No token found var name
#   TP_ERR_NO_VAR_TOKE_ARG		# No token argument var name
#   TP_ERR_NOT_INT_ARGS_MIN	# Number of minimum args is not an integer
#   TP_ERR_NOT_INT_ARGS_MAX	# Number of maximum args is not an integer
#   TP_ERR_ARGS_RANGE			# Minimum args greater than maximum args
#   TP_ERR_UNK_TOK				# Unknown token
#   TP_ERR_NO_TOK_ARG			# No argument for token
#   TP_ERR_TOK_SET				# Token already set
#   TP_ERR_NO_VAL_TOK			# Read token instead of value
#
#*******************************************************************************
#*                                                                             *
#*                              Global Variables                               *
#*                                                                             *
#*******************************************************************************

# Indexes
# -------
declare -r TP_TI=0							# Element token index
declare -r TP_FI=1							# Element found flag index
declare -r TP_MNI=2							# Element min args index
declare -r TP_MXI=3							# Element max args index
declare -r TP_AI=4							# Element argument variable index

# Error Codes
# ------------
declare -r TP_ERR_NONE=0					# No error
declare -r TP_ERR_NUM_ARGS=1				# Incorrect number of input arguments
declare -r TP_ERR_NO_ARY_INPUT=2			# No input array variable name
declare -r TP_ERR_NO_ARY_PARSE=3			# No parse array variable name
declare -r TP_ERR_NO_VAR_NUMTOKS=4		# No number of tokens variable name
declare -r TP_ERR_NO_VAR_LAST_II=5		# No Last Input Array Index variable name
declare -r TP_ERR_NO_VAR_LAST_PI=6		# No Last Parse Array Index variable name
declare -r TP_ERR_NO_VAR_LAST_AI=7		# No Last Argument Index variable name
declare -r TP_ERR_NO_VAR_TOKE_ELM=8		# No token for element in parse array 
declare -r TP_ERR_NO_VAR_TOKE_FND=9		# No token found var name in elm in parse ary
declare -r TP_ERR_NO_VAR_TOKE_ARG=10	# No token arg var name in elm in parse ary
declare -r TP_ERR_NOT_INT_ARGS_MIN=11	# Min args is not an int in elm in parse ary
declare -r TP_ERR_NOT_INT_ARGS_MAX=12	# Max args is not an int in elm in parse ary
declare -r TP_ERR_ARGS_RANGE=13			# Min args greater than max args in parse ary
declare -r TP_ERR_UNK_TOK=14				# Unknown token
declare -r TP_ERR_NO_TOK_ARG=15			# No argument for token
declare -r TP_ERR_TOK_SET=16				# Token already set
declare -r TP_ERR_NO_VAL_TOK=17			# Read token instead of value
declare -r TP_ERR_TOK_MAND=18				# Mandatory token not found
declare -r TP_ERR_TOK_INV=19				# Invalid token

TP_ERR_TOTAL=20								# Total number of error values

# Error Message Array
# ~~~~~~~~~~~~~~~~~~~
#
declare -a GC_TP_ERR_MSG_ARY				# Constant Array

GC_TP_ERR_MSG_ARY[$TP_ERR_NONE]="No error"
GC_TP_ERR_MSG_ARY[$TP_ERR_NUM_ARGS]="Incorrect number of input arguments"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_ARY_INPUT]="No input array variable name"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_ARY_PARSE]="No parse array variable name"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAR_NUMTOKS]="No number of tokens variable name"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAR_LAST_II]="No Last Input Array Index variable name"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAR_LAST_PI]="No Last Parse Array Index variable name"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAR_LAST_AI]="No Last Argument Index variable name"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAR_TOKE_ELM]="No token for element in parse array"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAR_TOKE_FND]="No Token Found variable name in parse array"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAR_TOKE_ARG]="No Token Argument variable name in parse array"
GC_TP_ERR_MSG_ARY[$TP_ERR_NOT_INT_ARGS_MIN]="Minimum arguments for token is not an integer in parse array"
GC_TP_ERR_MSG_ARY[$TP_ERR_NOT_INT_ARGS_MAX]="Maximum arguments for token is not an integer in parse array"
GC_TP_ERR_MSG_ARY[$TP_ERR_ARGS_RANGE]="Minimum arguments greater than maximum arguments in parse array"
GC_TP_ERR_MSG_ARY[$TP_ERR_UNK_TOK]="Unknown token"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_TOK_ARG]="No argument for token"
GC_TP_ERR_MSG_ARY[$TP_ERR_TOK_SET]="Token has already been processed"
GC_TP_ERR_MSG_ARY[$TP_ERR_NO_VAL_TOK]="Read next token instead of value for token"
GC_TP_ERR_MSG_ARY[$TP_ERR_TOK_MAND]="Mandatory token missing"
GC_TP_ERR_MSG_ARY[$TP_ERR_TOK_INV]="Invalid token"

readonly -a GC_TP_ERR_MSG_ARY

#*******************************************************************************
#*                                                                             *
#*                                  Functions                                  *
#*                                                                             *
#*******************************************************************************

#*******************************************************************************
#*                       Token Parser Exit Status Decode                       *
#*******************************************************************************
#
# Function: Returns status message for TokParse exit status.
#
# Input:
#   Arg1  TokParse error code.
#   Arg2  Input array variable name.
#   Arg3  Parse array variable name.
#   Arg4  Last Input Array index.
#   Arg5  Last Parse Array index.
#   Arg6  Last Argument index.
#   Arg7  Message return variable name.
#
# Output:
#   Arg7  Variable contains error message.
#
function TokParse_StatDecode ()
{
   local TokErr=$1
   local -n __InAry=$2
   local -n __ParseAry=$3
   local Last_ii=$4
   local Last_pi=$5
   local Last_ai=$6
   local __TokStatMsgRet=$7
   local __TokStatMsg=""

   case "$TokErr" in
      $TP_ERR_NONE)										# No error
         __TokStatMsg=""
      ;;

      $TP_ERR_NUM_ARGS)									# Wrong number of input args
         __TokStatMsg=""
      ;;

      $TP_ERR_NO_ARY_INPUT)							# No input array variable name
         __TokStatMsg=""
      ;;

      $TP_ERR_NO_ARY_PARSE)							# No parse array variable name
         __TokStatMsg=""
      ;;

      $TP_ERR_NO_VAR_NUMTOKS)							# No number of tokens var name
         __TokStatMsg=""
      ;;

      $TP_ERR_NO_VAR_LAST_II)							# No Last Input Array Index var name
         __TokStatMsg=""
      ;;

      $TP_ERR_NO_VAR_LAST_PI)							# No Last Parse Array Index var name
         __TokStatMsg=""
      ;;

      $TP_ERR_NO_VAR_LAST_AI)							# No Last Argument Index variable name
         __TokStatMsg=""
      ;;

      $TP_ERR_NO_VAR_TOKE_ELM)						# No token in element in parse array
         __TokStatMsg="Element \"$Last_pi\""
      ;;

      $TP_ERR_NO_VAR_TOKE_FND)						# No token found var name
         __TokStatMsg="Element \"$Last_pi\""
      ;;

      $TP_ERR_NO_VAR_TOKE_ARG)						# No token argument var name
         __TokStatMsg="Element \"$Last_pi\""
      ;;

      $TP_ERR_NOT_INT_ARGS_MIN)						# Number of arguments is not an integer
         __TokStatMsg="Element \"$Last_pi\""
      ;;

      $TP_ERR_NOT_INT_ARGS_MAX)						# Number of arguments is not an integer
         __TokStatMsg="Element \"$Last_pi\""
      ;;

      $TP_ERR_ARGS_RANGE)								# Number of arguments is not an integer
         __TokStatMsg="Element \"$Last_pi\""
      ;;

      $TP_ERR_UNK_TOK)		# Unknown token
         __TokStatMsg="Token \"${__InAry[$Last_ii]}\""
      ;;

      $TP_ERR_NO_TOK_ARG)			# No argument for token
         __TokStatMsg="Token \"${!__ParseAry[$Last_pi]:TP_TI:1}\""
      ;;

      $TP_ERR_TOK_SET)		# Token already set
         __TokStatMsg="Token \"${__InAry[$Last_ii]}\""
      ;;

      $TP_ERR_NO_VAL_TOK)		# Read token instead of value
         __TokStatMsg="Token \"${!__ParseAry[$Last_pi]:TP_TI:1}\""
      ;;

      *)
         __TokStatMsg="Unknown error"
      ;;
   esac
					# Return exit message
   eval $__TokStatMsgRet="'$__TokStatMsg'"
}

#*******************************************************************************
#*                           Token Parser Token Check                          *
#*******************************************************************************
#
# Function: Checks for mandatory and optional tokens. Returns error if
#           mandatory token not found, or if invalid token found (not mandatory
#           or optional).
#
# Input:
#   Arg1  Parse array variable name.
#   Arg2  Mandatory token string, tokens separated by spaces.
#   Arg3  Optional token string, tokens separated by spaces.
#   Arg4  Invalid token return variable name.
#
# Output:
#   Arg4  Variable contains invalid token.
#
#   Return Status:
#      TP_ERR_NONE			No error
#      TP_ERR_TOK_MAND		Mandatory token not found
#      TP_ERR_TOK_INV		Invalid token
#

function TokParse_TokChk ()
{
   local -n __ParseAry=$1
   local TokMandStr="$2"
   local TokOptStr="$3"
   local __InvTokRet=$4									# Invalid tok var name
   local __InvTok=""										# Invalid token var
   local ParseArySize=0									# Parse array size
   local pi=0												# Parse array index
   local TokFndFlg=0										# Token found flag
   local RetStat=$TP_ERR_NONE							# Return status

   #DbgPrint "Parse Array name = ${!__ParseAry}"
   ParseArySize=${#__ParseAry[@]}					# Get parse array size
   #DbgPrint "Parse Array size = $ParseArySize"

   TokMandStr=`echo "$TokMandStr" | tr -s ' '`	# Del double spaces
																# Del white space
   TokMandStr="$(echo -e "${TokMandStr}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
   TokMandStr=`echo ${TokMandStr// /|}`			# Replace spaces with |
   #DbgPrint "Mandatory token check string = \"$TokMandStr\""

   TokOptStr=`echo "$TokOptStr" | tr -s ' '`		# Del double and white space
																# Del white space
   TokOptStr="$(echo -e "${TokOptStr}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
   TokOptStr=`echo ${TokOptStr// /|}`				# Replace spaces with |
   #DbgPrint "Optional token check string = \"$TokOptStr\""

   for (( pi=0; pi < $ParseArySize; pi++ )); do	# Loop through parse array

      InTok=${!__ParseAry[pi]:TP_TI:1}				# Get token
      #DbgPrint "Token from parse array index \"$pi\" = \"$InTok\""
      __ElmVarName=${!__ParseAry[pi]:TP_FI:1}	# Get found flag var name
      #DbgPrint "Found Flag Var name from parse array index \"$pi\" = \"$__ElmVarName\""
      TokFndFlg=${!__ElmVarName}						# Get found flag
      #DbgPrint "Found Flag from parse array index \"$pi\" = \"$TokFndFlg\""
      if [ $TokFndFlg -eq 0 ]; then					# If token not found
																# If token mandatory
         if [[ $InTok =~ ^($TokMandStr)$ ]]; then
            #DbgPrint "Mandatory token not found, breaking with error"
            __InvTok="$InTok"
            RetStat=$TP_ERR_TOK_MAND				# Set error status
            break											# Exit loop
         fi
      else													# If found and not mandatory or optional
         if [[ ! $InTok =~ ^($TokMandStr)$ ]] && [[ ! $InTok =~ ^($TokOptStr)$ ]]; then
            #DbgPrint "Token not mandatory or optional, breaking with error"
            __InvTok="$InTok"
            RetStat=$TP_ERR_TOK_INV					# Set error status
            break											# Exit loop
         fi
      fi
   done

   #DbgPrint "Return status = \"$RetStat\", Invalid token = \"$__InvTok\""
   eval $__InvTokRet="'$__InvTok'"					# Return invalid token
   return $RetStat
}



#*******************************************************************************
#*                     Token Parser Clear Space Only Values                    *
#*******************************************************************************
#
# Function: Checks for values that are all spaces and clears them if found.
#
# Input:
#   Arg1  Parse array variable name.
#
# Output:
#   Arg	  All space only values are cleared.
#
#   Return Status:
#      0		# No error
#
function TokParse_SpcClr ()
{
   local -n __ParseAry=$1		# Parse array variable name
   local -n __ElmArgAry			# Element argument array name
   local ParseArySize=0			# Parse array size
   local NumArgsMin=0			# Min number of arguments for token
   local NumArgsMax=0			# Max number of arguments for token
   local pi=0				# Last parse array index
   local ai=0				# Last arg array index
   local AryVarFlg=0			# Array variable detected flag
   local ArgElm=""			# Element argument

   #DbgPrint "Parse Array name = ${!__ParseAry}"
   ParseArySize=${#__ParseAry[@]}		# Get parse array size
   #DbgPrint "Parse Array size = $ParseArySize"

   #DbgPrint "Clearing all space only Parse Array values"
   for (( pi=0; pi < $ParseArySize; pi++ )); do	# Loop through parse array
      NumArgsMin="${!__ParseAry[pi]:TP_MNI:1}"	# Get minimum number of args
      NumArgsMax="${!__ParseAry[pi]:TP_MXI:1}"	# Get maximum number of args
      #DbgPrint "Number of minimum args for parse array index \"$pi\" = \"$NumArgsMin\""
      #DbgPrint "Number of maximum args for parse array index \"$pi\" = \"$NumArgsMax\""

      if [ $NumArgsMax -gt 0 ]; then		# If we have arg
						# Get Argument var name
         __ElmVarName=${!__ParseAry[pi]:TP_AI:1}
         #DbgPrint "Argument var name for array index \"$pi\" = \"$__ElmVarName\""
         if [ $NumArgsMax -eq 1 ]; then		# If arg var isn't array
            ElmArg=${!__ElmVarName}		# Get arg from element
            #DbgPrint "Element Argument var \"$__ElmVarName\" = \"$ElmArg\""
						# If all spaces
            if [ "$ElmArg" != "" ] && [[ -z "${ElmArg// }" ]]; then
               #DbgPrint "All spaces detected, clearing Element Argument var \"$__ElmVarName\""
               eval $__ElmVarName=""		# Clear var
            fi
         else					# If array variable
            unset -n __ElmArgAry		# Have to redeclare local named
            local -n __ElmArgAry		# variable or value won't change
            __ElmArgAry="$__ElmVarName"		# Set array variable name
						# Loop through argument vars
            for (( ai=0; ai < $NumArgsMax; ai++ )); do
               ElmArg=${__ElmArgAry[ai]}	# Get arg from element
               #DbgPrint "Element Array Argument var \"$__ElmVarName\" index \"$ai\" = \"$ElmArg\""
						# If all spaces
               if [ "$ElmArg" != "" ] && [[ -z "${ElmArg// }" ]]; then
                  #DbgPrint "All spaces detected, clearing Element Argument var \"$__ElmVarName\" index \"$ai\""
                  __ElmArgAry[ai]=""		# Clear var
               fi
            done				# End process argument loop
         fi
      fi
   done						# End of process parse ary loop
   return 0
}

#*******************************************************************************
#*                                                                             *
#*                                     Main                                    *
#*                                                                             *
#*******************************************************************************
#
function TokParse ()
{
   local -n __InAry=$1			# Input array variable name
   local -n __ParseAry=$2		# Parse array variable name
   local __NumToksRet=$3		# Number of tokens found variable name
   local __Last_ii=$4			# Last input array index variable name
   local __Last_pi=$5			# Last parse array index variable name
   local __Last_ai=$6			# Last arg array index variable name
   local InArySize=0			# Input array size
   local ParseArySize=0			# Parse array size
   local __NumToks=0			# Number of tokens found
   local __ElmVarName=""		# Element variable name
   local -n __ElmArgAry			# Element argument array name
   local InTok=""			# Token read from input array
   local __InVal=""			# Value read from input array
   local __ii=0				# Last input array index
   local __pi=0				# Last parse array index
   local __ai=0				# Last arg array index
   local NumArgsMin=0			# Min number of arguments for token
   local NumArgsMax=0			# Max number of arguments for token
   local TokStr=""			# All tokens string
   local ElmTok=""			# Token read from parse array element
   local TokFndFlg=0			# Token found flag
   local FirstPassFlg=1			# First pass flag
   local AryVarFlg=0			# Array variable detected flag
   local RetStat=$TP_ERR_NONE	# Return status

#
# ---------------------
# Check Input Variables
# ---------------------
#
   #DbgPrint "Checking input variables"
   if [ "$#" -ne 6 ]; then			# Wrong number of arguments
      #DbgPrint "ERROR: Incorrect number of input arguments - \"$#\""
      RetStat=$TP_ERR_NUM_ARGS
   elif [ -z "$__InAry" ]; then
      #DbgPrint "ERROR: No Input Array variable name"
      RetStat=$TP_ERR_NO_ARY_INPUT
   elif [ -z "$__ParseAry" ]; then
      #DbgPrint "ERROR: No Parse Array variable name"
      RetStat=$TP_ERR_NO_ARY_PARSE
   elif [ -z "$__NumToksRet" ]; then
      #DbgPrint "ERROR: No Number of Tokens Parsed variable name"
      RetStat=$TP_ERR_NO_VAR_NUMTOKS
   elif [ -z "$__Last_ii" ]; then
      #DbgPrint "ERROR: No Last Input Array Index variable name"
      RetStat=$TP_ERR_NO_VAR_LAST_II
   elif [ -z "$__Last_pi" ]; then
      #DbgPrint "ERROR: No Last Parse Array Index variable name"
      RetStat=$TP_ERR_NO_VAR_LAST_PI
   elif [ -z "$__Last_ai" ]; then
      #DbgPrint "ERROR: No Last Argument Index variable name"
      RetStat=$TP_ERR_NO_VAR_LAST_AI
   fi

#
# ------------------
# Clear Parse Values
# ------------------
#
   if [ $RetStat -eq 0 ]; then			# If no errors
      TokStr=""
      FirstPassFlg=1
 
      #DbgPrint "Input Array name = ${!__InAry}"
      InArySize=${#__InAry[@]}			# Get input array size
      #DbgPrint "Input Array size = $InArySize"

      #DbgPrint "Parse Array name = ${!__ParseAry}"
      ParseArySize=${#__ParseAry[@]}		# Get parse array size
      #DbgPrint "Parse Array size = $ParseArySize"

      #DbgPrint "Clearing Parse Array and output variables"
      __NumToks=0
      eval $__NumToksRet="'$__NumToks'"		# Clear number of toks parsed
      eval $__Last_ii=0				# Clear last input array index
      eval $__Last_pi=0				# Clear last parse array index
      eval $__Last_ai=0				# Clear last argument index
						# Loop through parse array
      for (( __pi=0; __pi < $ParseArySize; __pi++ )); do

         InTok=${!__ParseAry[__pi]:TP_TI:1}	# Get token
         if [ ! -z "$InTok" ]; then		# If we have a token
            if [ $FirstPassFlg -eq 0 ]; then	# If not first pass
               TokStr="$TokStr|"		# Add | to token string
            fi
         else					# If no var name
            #DbgPrint "ERROR: No token for parse array index \"$__pi\""
            RetStat=$TP_ERR_NO_VAR_TOKE_ELM
            break
         fi

         FirstPassFlg=0				# Clear first pass flag
         TokStr="$TokStr$InTok"			# Add token to string
         #DbgPrint "Token string = \"$TokStr\""
						# Get Found Flag var name
         __ElmVarName=${!__ParseAry[__pi]:TP_FI:1}
         if [ ! -z "$__ElmVarName" ]; then	# If we have a name
            #DbgPrint "Clearing Found Var \"$__ElmVarName\" for parse array index \"$__pi\""
            eval $__ElmVarName=0		# Clear not Found Flag
         else					# If no var name
            #DbgPrint "ERROR: No Found var name for parse array index \"$__pi\""
            RetStat=$TP_ERR_NO_VAR_TOKE_FND
            break
         fi
						# Get minimum number of args
         NumArgsMin="${!__ParseAry[__pi]:TP_MNI:1}"
						# If not an integer
         if [[ ! $NumArgsMin =~ ^[0-9]+$ ]]; then
            #DbgPrint "ERROR: Number of arguments \"$NumArgsMin\" for parse array index \"$__pi\" is not an integer"
            RetStat=$TP_ERR_NOT_INT_ARGS_MIN
            break
         fi
						# Get maximum number of args
         NumArgsMax="${!__ParseAry[__pi]:TP_MXI:1}"
						# If not an integer
         if [[ ! $NumArgsMax =~ ^[0-9]+$ ]]; then
            #DbgPrint "ERROR: Number of arguments \"$NumArgsMax\" for parse array index \"$__pi\" is not an integer"
            RetStat=$TP_ERR_NOT_INT_ARGS_MAX
            break
         fi
						# If invalid argument range
         if [ $NumArgsMin -gt $NumArgsMax ]; then
            #DbgPrint "ERROR: Number of minimum arguments \"$NumArgsMax\" is greater than number of maximum arguments \"$NumArgsMax\"  for parse array index \"$__pi\""
            RetStat=$TP_ERR_ARGS_RANGE
            break
         fi

         #DbgPrint "Number of minimum args for parse array index \"$__pi\" = \"$NumArgsMin\""
         #DbgPrint "Number of maximum args for parse array index \"$__pi\" = \"$NumArgsMax\""

         if [ $NumArgsMax -gt 0 ]; then		# If we have arguments
						# Get Argument var name
            __ElmVarName=${!__ParseAry[__pi]:TP_AI:1}
            #DbgPrint "Argument variable name for parse array index \"$__pi\" is \"$__ElmVarName\""
            if [ -z "$__ElmVarName" ]; then	# If no arg var name	
               #DbgPrint "ERROR: No Argument var name for for parse array index \"$__pi\""
               RetStat=$TP_ERR_NO_VAR_TOKE_ARG
               break
            fi

            if [ $NumArgsMax -eq 1 ]; then	# If arg var isn't array
               #DbgPrint "Clearing non-array argument \"$__ElmVarName\" for parse array index \"$__pi\""
               eval $__ElmVarName=""		# Clear Argument var
            else				# If arg is array
               #DbgPrint "Clearing array argument \"$__ElmVarName\" for parse array index \"$__pi\""
               unset -n __ElmArgAry		# Have to redeclare local named
               local -n __ElmArgAry		# variable or value won't change
               __ElmArgAry="$__ElmVarName"	# Set array variable name
               __ElmArgAry=()			# Clear array
            fi
         fi

         if [ $RetStat -ne 0 ]; then		# If error
            #DbgPrint "ERROR: Parse Array clear error found, breaking from main loop"
            break
         fi
      done					# End of clear parse array loop

#
# ------------------
# Parse Input Tokens
# ------------------
#
      if [ $RetStat -eq 0 ]; then		# If no errors
						# Loop through input array
         for (( __ii=0; __ii < $InArySize; __ii++ )); do
            InTok="${__InAry[__ii]}"		# Get input token
            #DbgPrint "Input Token $__ii: $InTok"
            TokFndFlg=0				# Clear token found flag
						# If unknown token
            if [[ ! $InTok =~ ^($TokStr)$ ]]; then
               #DbgPrint "Unknown token value at input array $__ii = \"$InTok\""
               RetStat=$TP_ERR_UNK_TOK	# Set unknown token status
               break
            fi
						# Loop through parse array
            for (( __pi=0; __pi < $ParseArySize; __pi++ )); do
						# Get token from element
               ElmTok=${!__ParseAry[__pi]:TP_TI:1}
               #DbgPrint "Parse Token value $__pi = $ElmTok"
						# If token found
               if [ "$InTok" == "$ElmTok" ]; then
                  #DbgPrint "Parse Token \"$InTok\" found"
						# Get Token Found var name
                  __ElmVarName=${!__ParseAry[__pi]:TP_FI:1}
                  #DbgPrint "Element Found var name = $__ElmVarName"
						# If token already processed
                  if [ ${!__ElmVarName} -ne 0 ]; then
                     #DbgPrint "Token \"$InTok\" already processed, setting bad return status"
                     RetStat=$TP_ERR_TOK_SET	# Set already processed status
                     break			# Break out of loop
                  fi
						# Get minimum number of args
                  NumArgsMin="${!__ParseAry[__pi]:TP_MNI:1}"
                  #DbgPrint "Minimum number of arguments for array index \"$__pi\" = \"$NumArgsMin\""
						# Get maximum number of args
                  NumArgsMax="${!__ParseAry[__pi]:TP_MXI:1}"
                  #DbgPrint "Maximum number of arguments for array index \"$__pi\" = \"$NumArgsMax\""
						# If we need arguments
                  if [ $NumArgsMax -gt 0 ]; then
						# Get Argument var name
                     __ElmVarName=${!__ParseAry[__pi]:TP_AI:1}
                     #DbgPrint "Argument var name for array index \"$__pi\" = \"$__ElmVarName\""
						# If arg var isn't array
                     if [ $NumArgsMax -eq 1 ]; then
                        #DbgPrint "Non-array argument detected for array index \"$__pi\""
                        AryVarFlg=0		# Clear array variable flag
                     else			# If arg is an array
                        #DbgPrint "Array argument detected for array index \"$__pi\""
                        AryVarFlg=1		# Set array variable flag
                        unset -n __ElmArgAry	# Have to redeclare local named
                        local -n __ElmArgAry	# variable or value won't change
						# Set array variable name
                        __ElmArgAry="$__ElmVarName"
                     fi
						# Loop through argument vars
                     for (( __ai=0; __ai < $NumArgsMax; __ai++ )); do
                        ((__ii++))		# Inc input array index
						# If we have more input
                        if [ $__ii -lt $InArySize ]; then
						# Read input argument
                           __InVal="${__InAry[__ii]}"
                           #DbgPrint "Input array value = \"$__InVal\""
						# Stop if it's a token
                           if [[ $__InVal =~ ^($TokStr)$ ]]; then
                              #DbgPrint "Read token \"$__InVal\" when expecting value, arg array index = \"$__ai\""
                                                # If we have minimum args
                              if [ $__ai -ge $NumArgsMin ]; then
                                 #DbgPrint "Read token \"$__InVal\", but minimum values input so continuing"
                                 ((__ii--))	# Backup input array index
                                 ((__ai--))	# Backup arg array index
                              else		# If not enough args
                                 #DbgPrint "Read token \"$__InVal\" instead of value, setting bad return status"
						# Set token instead of val stat
                                 RetStat=$TP_ERR_NO_VAL_TOK
                              fi
                              break		# Always break out of loop
                           fi
						# If not array variable
                           if [ $AryVarFlg -eq 0 ]; then
                              #DbgPrint "Setting Element Argument var \"$__ElmVarName\" to \"$__InVal\""
						# Write argument to var
                              eval $__ElmVarName="'$__InVal'"
                           else			# If array variable
                              #DbgPrint "Setting Element Array Argument var \"$__ElmVarName\" index \"$__ai\" to \"$__InVal\""
						# Write argument to array var
                              __ElmArgAry[__ai]="$__InVal"
                           fi
                        else			# If no argument
                                                # If we have minimum args
                           if [ $__ai -ge $NumArgsMin ]; then
                              #DbgPrint "Out of values, but minimum values input so continuing"
                              ((__ai--))	# It's okay, backup arg ary idx
                           else			# If not enough args
                              #DbgPrint "No value for \"$InTok\", setting bad return status"
						# Set no arg status
                              RetStat=$TP_ERR_NO_TOK_ARG
                           fi
                           break		# Break out of loop
                        fi
                     done			# End of argument input loop
                  fi

                  if [ $RetStat -eq 0 ]; then	# If no error
                     #DbgPrint "Setting Token Found Flag to 1"
						# Get Token Found var name
                     __ElmVarName=${!__ParseAry[__pi]:TP_FI:1}
                     eval $__ElmVarName=1	# Set Token Found var
                     TokFndFlg=1		# Set token found flag
                     ((__NumToks++))		# Inc number of tokens
                  fi
                  break				# Always break out of loop
               fi
            done				# End of process parse ary loop

            if [ $TokFndFlg -eq 0 ]; then	# If token not found
#               if [ $RetStat -eq 0 ]; then	# If not other error
#                 #DbgPrint "Parse Option \"$InTok\" not found, setting bad return status"
#                 RetStat=$TokPrsErr_NotFound	# Set token not found status
#               fi
               break				# Break out of looop
            fi
         done					# End of process input ary loop
      fi
      eval $__NumToksRet="'$__NumToks'"		# Return number of tokens found
      eval $__Last_ii="'$__ii'"			# Return last input array index
      eval $__Last_pi="'$__pi'"			# Return last parse array index
      eval $__Last_ai="'$__ai'"			# Return last argument index
   fi

   return $RetStat
}
