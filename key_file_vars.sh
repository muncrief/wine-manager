#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                                Key File Variables                           *
#*                                                                             *
#*                                                                             *
#*******************************************************************************

# ~~~~~~~~~~~
# Error Codes
# ~~~~~~~~~~~
declare -r GC_KF_ERR_NONE=0								# No error
declare -r GC_KF_ERR_KEY_NOT_R=1							# Key file not readable
declare -r GC_KF_ERR_KEY_NOT_W=2							# Key file not writeable
declare -r GC_KF_ERR_KEY_NOT_RW=3						# Key file not read/write
declare -r GC_KF_ERR_KEY_EXISTS=5						# Key already exists
declare -r GC_KF_ERR_KEY_NEXIST=6						# Key doesn't exist

declare -r GC_KF_ERR_TOTAL=7								# Total number of error values


# Error Message Array
# ~~~~~~~~~~~~~~~~~~~
#
declare -a GC_KF_ERR_MSG_ARY							# Constant Array

GC_KF_ERR_MSG_ARY[$GC_KF_ERR_NONE]="No error"
GC_KF_ERR_MSG_ARY[$GC_KF_ERR_KEY_NOT_R]="Key file not readable"
GC_KF_ERR_MSG_ARY[$GC_KF_ERR_KEY_NOT_W]="Key file not writeable"
GC_KF_ERR_MSG_ARY[$GC_KF_ERR_KEY_NOT_RW]="Key file not read/write"
GC_KF_ERR_MSG_ARY[$GC_KF_ERR_KEY_EXISTS]="Key already exists"
GC_KF_ERR_MSG_ARY[$GC_KF_ERR_KEY_NEXIST]="Key doesn't exist"

readonly -a GC_KF_ERR_MSG_ARY

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Key Special Encoded Character Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Elements
# ~~~~~~~~
# Format: ASCII character, Character hex code
#
																# Backslash (Must be first for encode, last for decode!!!)
declare -r GC_KF_CHR_HEX_ELM_1=('\' "$(printf '\' | od -A n -t x1 | xargs)")
																# Hashmark
declare -r GC_KF_CHR_HEX_ELM_2=("#" "$(printf '#' | od -A n -t x1 | xargs)")
																# Equals
declare -r GC_KF_CHR_HEX_ELM_3=("=" "$(printf '=' | od -A n -t x1 | xargs)")
																# Asterisk
declare -r GC_KF_CHR_HEX_ELM_4=("*" "$(printf '*' | od -A n -t x1 | xargs)")
																# Colon
declare -r GC_KF_CHR_HEX_ELM_5=(":" "$(printf ':' | od -A n -t x1 | xargs)")
																# Ampersand
declare -r GC_KF_CHR_HEX_ELM_6=("&" "$(printf '&' | od -A n -t x1 | xargs)")

# Encode Array
# ~~~~~~~~~~~~
declare -a GC_KF_CHR_HEX_ENC_ARY=(
   GC_KF_CHR_HEX_ELM_1[@]
   GC_KF_CHR_HEX_ELM_2[@]
   GC_KF_CHR_HEX_ELM_3[@]
   GC_KF_CHR_HEX_ELM_4[@]
   GC_KF_CHR_HEX_ELM_5[@]
   GC_KF_CHR_HEX_ELM_6[@]
)
readonly -a GC_KF_CHR_HEX_ENC_ARY

GC_KF_CHR_HEX_ENC_ARY_SIZE=${#GC_KF_CHR_HEX_ENC_ARY[@]}

# Decode Array
# ~~~~~~~~~~~~
declare -a GC_KF_CHR_HEX_DEC_ARY=(
   GC_KF_CHR_HEX_ELM_6[@]
   GC_KF_CHR_HEX_ELM_5[@]
   GC_KF_CHR_HEX_ELM_4[@]
   GC_KF_CHR_HEX_ELM_3[@]
   GC_KF_CHR_HEX_ELM_2[@]
   GC_KF_CHR_HEX_ELM_1[@]
)
readonly -a GC_KF_CHR_HEX_DEC_ARY

GC_KF_CHR_HEX_DEC_ARY_SIZE=${#GC_KF_CHR_HEX_DEC_ARY[@]}


