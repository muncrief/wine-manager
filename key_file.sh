#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                                Key File Functions                           *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
#	Description:
#		Functions to manage key names and values in text files. The
#		key names and values are stored in standard ASCII format as follows:
#
#		name=value
#
#		Note that both the key name and value strings have special
#		characters that are automatically encoded/decoded when
#		reading/writing from the key file. Therefore the key file should
#		never be manually edited.
#
#		Key names and values have been tested to function correctly with
#		most commong special characters. Problems with other characters can be
#		corrected by adding them to the "Key Special Encoded Character
#		Array" in the "Key File Variables" file. The following special
#		characters have been verified to function correctly: 
#
#		~ ! @ # $ % ^ & * ( ) _ + ` - = { } | \ : " ; ' < > ? , . /
#
#*******************************************************************************
#*                                 Key String Encode                           *
#*******************************************************************************
#
# Function:
#	Encodes a string for use as a key name or value. All special characters are
#	replaced by their hex code preceded by '\x'. For example, a '#' character
#	would be converted to '\x23'. 
#
# Input:
#	Arg1 = Unencoded Key string.
#	Arg2 = Return encoded key string variable name.
#
# Output:
#	Arg2 = Encoded key string.
#
# Exit Status:
#	No status passed.
#
function KeyEnc ()
{
   local l_KeyStrIn="$1"
   local -n __l_KE_KeyStrOut="$2"
   local l_ChrAscii=""
   local l_ChrHex=0
   local l_i=0

	DbgPrint "${FUNCNAME[0]}: Entered: Key string in = \"$l_KeyStrIn\"" 1

	__l_KE_KeyStrOut=""
	for ((l_i=0; l_i < $GC_KF_CHR_HEX_ENC_ARY_SIZE; l_i++)); do
		l_ChrAscii="${!GC_KF_CHR_HEX_ENC_ARY[l_i]:0:1}"
		l_ChrHex=${!GC_KF_CHR_HEX_ENC_ARY[l_i]:1:1}

		DbgPrint "${FUNCNAME[0]}: Char = \"$l_ChrAscii\", Hex = \"$l_ChrHex\"" 1
		__l_KE_KeyStrOut=${l_KeyStrIn//"$l_ChrAscii"/"\x${l_ChrHex}"}
		DbgPrint "${FUNCNAME[0]}: String after \"$l_ChrAscii\" to \"\x$l_ChrHex\" = \"$__l_KE_KeyStrOut\"" 1
		l_KeyStrIn="$__l_KE_KeyStrOut"
		DbgPrint "${FUNCNAME[0]}: New key string = \"$l_KeyStrIn\"" 1
	done

	DbgPrint "${FUNCNAME[0]}: Exiting" 1
	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                         Key String Encode With Escape                       *
#*******************************************************************************
#
# Function:
#	Encodes a string for use as a key name or value with escapes. All special
#	characters are replaced by their hex code preceded by '\\\x'. For example,
#	a '#' character would be converted to '\\\x23'. 
#
# Input:
#	Arg1 = Unencoded Key string.
#	Arg2 = Return encoded key string variable name.
#
# Output:
#	Arg2 = Encoded key string.
#
# Exit Status:
#	No status passed.
#
function KeyEncEsc ()
{
   local l_KeyStrIn="$1"
   local -n __l_KEE_KeyStrOut="$2"
   local l_ChrAscii=""
   local l_ChrHex=0
   local l_i=0

	DbgPrint "${FUNCNAME[0]}: Entered: Key string in = \"$l_KeyStrIn\"" 1

	__l_KEE_KeyStrOut=""
	for ((l_i=0; l_i < $GC_KF_CHR_HEX_ENC_ARY_SIZE; l_i++)); do
		l_ChrAscii="${!GC_KF_CHR_HEX_ENC_ARY[l_i]:0:1}"
		l_ChrHex=${!GC_KF_CHR_HEX_ENC_ARY[l_i]:1:1}
		DbgPrint "${FUNCNAME[0]}: Char = \"$l_ChrAscii\", Hex = \"$l_ChrHex\"" 1

		__l_KEE_KeyStrOut=${l_KeyStrIn//"$l_ChrAscii"/"\\\x${l_ChrHex}"}
		DbgPrint "${FUNCNAME[0]}: String after \"$l_ChrAscii\" to \"\\\x$l_ChrHex\" = \"$__l_KEE_KeyStrOut\"" 1

		l_KeyStrIn="$__l_KEE_KeyStrOut"
		DbgPrint "${FUNCNAME[0]}: New key string = \"$l_KeyStrIn\"" 1
	done

	DbgPrint "${FUNCNAME[0]}: Exiting" 1
	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                                  Key String Decode                          *
#*******************************************************************************
#
# Function:
#	Decodes a string used as a key name or value. All escaped hex code strings
#	are replaced by their characters. 
#
# Input:
#	Arg1 = Encoded Key string.
#	Arg2 = Return decoded key string variable name.
#
# Output:
#	Arg2 = Decoded key string.
#
# Exit Status:
#	No status passed.
#
function KeyDec ()
{
   local l_KeyStrIn="$1"
   local -n __l_KD_KeyStrOut="$2"
   local l_ChrAscii=""
   local l_ChrHex=0
   local l_i=0

	DbgPrint "${FUNCNAME[0]}: Entered: Key string in = \"$l_KeyStrIn\"" 1

	__l_KD_KeyStrOut=""
	for ((l_i=0; l_i < $GC_KF_CHR_HEX_DEC_ARY_SIZE; l_i++)); do
		l_ChrAscii="${!GC_KF_CHR_HEX_DEC_ARY[l_i]:0:1}"
		l_ChrHex=${!GC_KF_CHR_HEX_DEC_ARY[l_i]:1:1}
		DbgPrint "${FUNCNAME[0]}: Char = \"$l_ChrAscii\", Hex = \"$l_ChrHex\"" 1

		__l_KD_KeyStrOut=${l_KeyStrIn//"\x${l_ChrHex}"/$l_ChrAscii}
		DbgPrint "${FUNCNAME[0]}: String after \"\x$l_ChrHex\" to \"$l_ChrAscii\" = \"$__l_KD_KeyStrOut\"" 1

		l_KeyStrIn="$__l_KD_KeyStrOut"
		DbgPrint "${FUNCNAME[0]}: New key string = \"$l_KeyStrIn\"" 1
	done

	DbgPrint "${FUNCNAME[0]}: Exiting" 1
	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                                  Add Key To File                            *
#*******************************************************************************
#
# Function:
#	Adds a key and value to a file. If key already exists an error is returned. 
#
# Input:
#	Arg1 = Key string.
#	Arg2 = Value string.
#	Arg3 = File pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	GC_KF_ERR_NONE = No error.
#	GC_KF_ERR_KEY_NOT_RW = File not writeable and readable error.
#	GC_KF_ERR_KEY_EXISTS = Key already exists.
#
function KeyAdd ()
{
   local l_Key="$1"
   local l_Value="$2"
   local l_File="$3"
   local l_KeyEnc=""
   local l_KeyEncEsc=""
   local l_ValueEnc=""

	DbgPrint "${FUNCNAME[0]}: Entered: Key name = \"$l_Key\", Value = \"$l_Value\", File = \"$l_File\"" 1
												# If file isn't read/write
	if [[ ! -r "$l_File" || ! -w "$l_File" ]]; then
		return $GC_KF_ERR_KEY_NOT_RW			# Return error
	fi

	KeyEncEsc "$l_Key" l_KeyEncEsc				# Encode key with escape
	DbgPrint "${FUNCNAME[0]}: Encoded key = \"$l_KeyEncEsc\"" 1
												# If key already exists
	if [ ! -z "`sed -n 's#\('"$l_KeyEncEsc"'\s*=\).*#\1#p' "$l_File"`" ]; then
		return $GC_KF_ERR_KEY_EXISTS			# Return error
	fi

	KeyEnc "$l_Key" l_KeyEnc					# Otherwise encode key
	KeyEnc "$l_Value" l_ValueEnc				# Encode value
	DbgPrint "${FUNCNAME[0]}: Encoded value = \"$l_ValueEnc\"" 1
												# Write encoded key/value to file
	echo "$l_KeyEnc=$l_ValueEnc" >> "$l_File"
	DbgPrint "${FUNCNAME[0]}: Exiting: Wrote key name = \"$l_KeyEnc\", Value = \"$l_ValueEnc\" to file \"$l_File\"" 1
	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                             Write Key Value To File                         *
#*******************************************************************************
#
# Function:
#	Changes the value of a key in a file. 
#
# Input:
#	Arg1 = Key string.
#	Arg2 = Value string.
#	Arg3 = File pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	GC_KF_ERR_NONE = No error.
#	GC_KF_ERR_KEY_NOT_RW = File not writeable and readable error.
#	GC_KF_ERR_KEY_NEXIST = Key doesn't exist.
#
function KeyWr ()
{
   local l_Key="$1"
   local l_Value="$2"
   local l_File="$3"
   local l_KeyEncEsc=""
   local l_ValueEncEsc=""

	DbgPrint "${FUNCNAME[0]}: Entered: Key name = \"$l_Key\", Value = \"$l_Value\", File = \"$l_File\"" 1
												# If file isn't read/write
	if [[ ! -r "$l_File" || ! -w "$l_File" ]]; then
		return $GC_KF_ERR_KEY_NOT_RW			# Return error
	fi

	KeyEncEsc "$l_Key" l_KeyEncEsc				# Encode key
	DbgPrint "${FUNCNAME[0]}: Encoded key = \"$l_KeyEncEsc\"" 1
												# If key doesn't exist
	if [ -z "`sed -n 's#\('"$l_KeyEncEsc"'\s*=\).*#\1#p' "$l_File"`" ]; then
		return $GC_KF_ERR_KEY_NEXIST			# Return error
	fi

	KeyEncEsc "$l_Value" l_ValueEncEsc			# Otherwise encode value
	DbgPrint "${FUNCNAME[0]}: Encoded value = \"$l_ValueEncEsc\"" 1
												# Change key value
	sed -i 's#\('"$l_KeyEncEsc"'\s*=\).*#\1'"$l_ValueEncEsc"'#' "$l_File"
	DbgPrint "${FUNCNAME[0]}: Exiting: Wrote key name = \"$l_KeyEncEsc\", Value = \"$l_ValueEncEsc\" to file \"$l_File\"" 1
	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                          Read Key Value From File                           *
#*******************************************************************************
#
# Function:
#	Reads the value of a key from a file.
#
# Input:
#	Arg1 = Key string.
#	Arg2 = Value string return variable name.
#	Arg3 = File pathname.
#
# Output:
#	Arg2 = Value string.
#
# Exit Status:
#	GC_KF_ERR_NONE = No error.
#	GC_KF_ERR_KEY_NOT_RW = File not writeable and readable error.
#	GC_KF_ERR_KEY_NEXIST = Key doesn't exist.
#
function KeyRd ()
{
   local l_Key="$1"
   local -n __l_KR_Value="$2"
   local l_File="$3"
   local l_KeyEncEsc=""
   local l_ValueEnc=""

	DbgPrint "${FUNCNAME[0]}: Entered: Key name = \"$l_Key\", Return value variable name = \"${!__l_KR_Value}\", File = \"$l_File\"" 1

	__l_KR_Value=""								# Clear return value
												# If file isn't read/write
	if [[ ! -r "$l_File" || ! -w "$l_File" ]]; then
		return $GC_KF_ERR_KEY_NOT_RW			# Return error
	fi

	KeyEncEsc "$l_Key" l_KeyEncEsc				# Encode key
	DbgPrint "${FUNCNAME[0]}: Encoded key = \"$l_KeyEncEsc\"" 1
												# If key doesn't exist
	if [ -z "`sed -n 's#\('"$l_KeyEncEsc"'\s*=\).*#\1#p' "$l_File"`" ]; then
		return $GC_KF_ERR_KEY_NEXIST			# Return error
	fi
												# Otherwise read encoded key value
	l_ValueEnc=`sed -n "s#^$l_KeyEncEsc\s*\= *##p" "$l_File"`
	DbgPrint "${FUNCNAME[0]}: Encoded value = \"$l_ValueEnc\"" 1

	KeyDec "$l_ValueEnc" __l_KR_Value			# Otherwise return decoded value
	DbgPrint "${FUNCNAME[0]}: Exiting: Decoded value = \"$__l_KR_Value\"" 1
	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                         List All Key Names in File                          *
#*******************************************************************************
#
# Function:
#	Lists all key names in a file.
#
# Input:
#	Arg1 = File pathname.
#	Arg2 = Key name return array variable name.
#	Arg3 = Key value return array variable name.
#
# Output:
#	Arg2 = Array of key names.
#	Arg3 = Array of key values.
#
# Exit Status:
#	GC_KF_ERR_NONE = No error.
#	GC_KF_ERR_KEY_NOT_R = File not readable error.
#
function KeyRdAll ()
{
   local l_File="$1"
   local -n __l_KRA_KeyNameAry="$2"
   local -n __l_KRA_KeyValAry="$3"
   local -a l_KeyNameAryEnc
   local l_KeyName
   local l_KeyNameEnc
   local l_KeyVal

	__l_KRA_KeyNameAry=()						# Clear return key name array
	__l_KRA_KeyValAry=()						# Clear return key value array

	if [ ! -r "$l_File" ]; then					# If file isn't readable
		return $GC_KF_ERR_KEY_NOT_R				# Return error
	fi
												# Get all encoded key names
	IFS=$'\n' l_KeyNameAryEnc=(`sed 's#=.*##' "$l_File"`)

	if [ ${#l_KeyNameAryEnc[@]} -gt 0 ]; then	# If we have keys
												# Get encoded Key name
		for l_KeyNameEnc in "${l_KeyNameAryEnc[@]}";
		do
			KeyDec "$l_KeyNameEnc" l_KeyName	# Decode key name
			__l_KRA_KeyNameAry+=("$l_KeyName")	# Add to name return array
												# Get key value
			KeyRd "$l_KeyName" l_KeyVal "$l_File"
			__l_KRA_KeyValAry+=("$l_KeyVal")	# Add to value return array
		done
	else										# If no keys
		return $GC_KF_ERR_KEY_NEXIST			# Return error
	fi

	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                    Add Key or Write Existing Key To File                    *
#*******************************************************************************
#
# Function:
#	Adds a key, or uses existing key, to write key string to a file. 
#
# Input:
#	Arg1 = Key string.
#	Arg2 = Value string.
#	Arg3 = File pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	GC_KF_ERR_NONE = No error.
#	GC_KF_ERR_KEY_NOT_RW = File not writeable and readable error.
#
function KeyAddWr ()
{
   local l_Key="$1"
   local l_Value="$2"
   local l_File="$3"

	DbgPrint "${FUNCNAME[0]}: Entered: Key name = \"$l_Key\", Value = \"$l_Value\", File = \"$l_File\"" 1
												# If file isn't read/write
	if [[ ! -r "$l_File" || ! -w "$l_File" ]]; then
		return $GC_KF_ERR_KEY_NOT_RW			# Return error
	fi
												# If key exists
	if KeyChk "$l_Key" "$l_File"; then
		DbgPrint "${FUNCNAME[0]}: Executing = KeyWr \"$l_Key\" \"$l_Value\" \"$l_File\"" 1
												# Change key value
		KeyWr "$l_Key" "$l_Value" "$l_File"
	else
		DbgPrint "${FUNCNAME[0]}: Executing = KeyAdd \"$l_Key\" \"$l_Value\" \"$l_File\"" 1
												# Add key value
		KeyAdd "$l_Key" "$l_Value" "$l_File"
	fi
}

#*******************************************************************************
#*                             Check if Key Is In File                         *
#*******************************************************************************
#
# Function:
#	Checks if key is in file. 
#
# Input:
#	Arg1 = Key string.
#	Arg2 = File pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	GC_KF_ERR_NONE = Key exists.
#	GC_KF_ERR_KEY_NEXIST = Key doesn't exist.
#
function KeyChk ()
{
   local l_Key="$1"
   local l_File="$2"
   local l_KeyEncEsc=""

	KeyEncEsc "$l_Key" l_KeyEncEsc				# Encode key
												# If key doesn't exist
	if [ -z "`sed -n 's#\('"$l_KeyEncEsc"'\s*=\).*#\1#p' "$l_File"`" ]; then
		return $GC_KF_ERR_KEY_NEXIST			# Return doesn't exist status
	fi
	return $GC_KF_ERR_NONE
}

#*******************************************************************************
#*                               Delete Key From File                          *
#*******************************************************************************
#
# Function:
#	Deletes key from a file. 
#
# Input:
#	Arg1 = Key string.
#	Arg2 = File pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	GC_KF_ERR_NONE = No error.
#	GC_KF_ERR_KEY_NOT_RW = File not writeable and readable error.
#	GC_KF_ERR_KEY_NEXIST = Key doesn't exist.
#
function KeyDel ()
{
   local l_Key="$1"
   local l_File="$2"
   local l_KeyEncEsc=""
												# If file isn't read/write
	if [[ ! -r "$l_File" || ! -w "$l_File" ]]; then
		return $GC_KF_ERR_KEY_NOT_RW			# Return error
	fi

	KeyEncEsc "$l_Key" l_KeyEncEsc				# Encode key
	DbgPrint "${FUNCNAME[0]}: Encoded key with escape = \"$l_KeyEncEsc\"" 1
												# If key doesn't exist
	if [ -z "`sed -n 's#\('"$l_KeyEncEsc"'\s*=\).*#\1#p' "$l_File"`" ]; then
		return $GC_KF_ERR_KEY_NEXIST			# Return error
	fi

	sed -i "\#^$l_KeyEncEsc\s*\= *#d" "$l_File"	# Otherwise delete key
	return $GC_KF_ERR_NONE
}
