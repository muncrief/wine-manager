#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                        Wine Manager V2 Global Variables                     *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
# ------------------
# Standard Variables
# ------------------
#
Dbg=0												# 1 to enable debug output
DbgLog=0											# 1 to enable debug logging
LogCmd="logger"								# System log command

# -------------------------
# Script Specific Constants
# -------------------------

# Error Codes
# -----------
declare -r WM_ERR_NONE=0					# No error
declare -r WM_ERR_INV_RESP=1				# Invalid response
declare -r WM_ERR_SRVC_START=2			# Service start
declare -r WM_ERR_SRVC_STOP=3				# Service stop
declare -r WM_ERR_SRVC_DSB=4				# Service disable
declare -r WM_ERR_SRVC_RELD=5				# Service reload
declare -r WM_ERR_BTL_NEXIST=6			# Bottle doesn't exist
declare -r WM_ERR_BTL_EXISTS=7			# Bottle already exists
declare -r WM_ERR_BTL_NNAME=8				# No bottle name
declare -r WM_ERR_BTL_RENAME=9			# Bottle rename failed
declare -r WM_ERR_BTL_ISDFLT=10			# Bottle can't be accessed because it's default
declare -r WM_ERR_BTL_XDGENB=11			# Bottle can't be accessed because it's XDG is enabled
declare -r WM_ERR_BTL_SYS=12				# System bottles cannot be accessed
declare -r WM_ERR_DIR_NEXIST=13			# Directory doesn't exist
declare -r WM_ERR_DIR_EXISTS=14			# Directory already exists
declare -r WM_ERR_DIR_RD=15				# Directory not readable
declare -r WM_ERR_DIR_WR=16				# Directory not writeable
declare -r WM_ERR_DIR_RW=17				# Directory not read/write
declare -r WM_ERR_DIR_CREATE=18			# Directory create error
declare -r WM_ERR_DIR_COPY=19				# Directory copy error
declare -r WM_ERR_DIR_MOVE=20				# Directory move error
declare -r WM_ERR_DIR_DEL=21				# Directory delete error
declare -r WM_ERR_DIR_NMERGE=22			# Not a merger file system.
declare -r WM_ERR_LNK_NEXIST=23			# Link doesn't exist
declare -r WM_ERR_LNK_EXISTS=24			# Link already exists
declare -r WM_ERR_LNK_CREATE=25			# Link create error
declare -r WM_ERR_LNK_DEL=26				# Link delete error
declare -r WM_ERR_FILE_CREATE=27			# File create error
declare -r WM_ERR_FILE_COPY=28			# File copy error
declare -r WM_ERR_FILE_MOVE=29			# File move error
declare -r WM_ERR_FILE_DEL=30				# File delete error
declare -r WM_ERR_FILE_NEXIST=31			# File not found
declare -r WM_ERR_FILE_EXISTS=32			# File already exists
declare -r WM_ERR_FILE_RD=33				# File not readable
declare -r WM_ERR_FILE_WR=34				# File not writeable
declare -r WM_ERR_FILE_RW=35				# File not read/write
declare -r WM_ERR_FILE_NEXEC=36			# File not executable
declare -r WM_ERR_ENV_NEXIST=37			# Environment variable doesn't exist

declare -r WM_ERR_CVAR_EXIST=38			# Configuration variable already exists
declare -r WM_ERR_CVAR_NEXIST=39			# Configuration variable doesn't exist
declare -r WM_ERR_CVAR_RD=40				# Configuration variable not readable
declare -r WM_ERR_CVAR_WR=41				# Configuration variable not writeable
declare -r WM_ERR_CVAR_RW=42				# Configuration variable not read/write
declare -r WM_ERR_CVAR_DEL=43				# Configuration variable cannot be deleted
declare -r WM_ERR_CVAR_INVVAL=44			# Configuration variable value is invalid

declare -r WM_ERR_XDG_ENB=45				# Host XDG already enabled
declare -r WM_ERR_XDG_DSB=46				# Host XDG already disabled
declare -r WM_ERR_PARM_INV=47				# Invalid parameter
declare -r WM_ERR_PARM_MISS=48			# Mandatory parameter missing
declare -r WM_ERR_UNK_FD_TYPE=49			# Unknown directory/file type
declare -r WM_ERR_UNK_CMD=50				# Unrecognized command
declare -r WM_ERR_UNK_ARG=51				# Unrecognized argument
declare -r WM_ERR_UNK_MODE=52				# Unrecognized mode
declare -r WM_ERR_UNK_OPT=53				# Unrecognized option
declare -r WM_ERR_NUM_ARGS=54				# Incorrect number of arguments
declare -r WM_ERR_NO_CMD=55				# No command
declare -r WM_ERR_INIT=56					# Wine Manager must be initialized 
declare -r WM_ERR_DEINIT=57				# Wine Manager must be deinitialized 
declare -r WM_ERR_RFRSH_XDG=58			# XDG refresh command failed
declare -r WM_ERR_TOTAL=59					# Total number of error values

# XDG Values
# ----------
declare -r GC_BTL_XDG_DSB=0				# Bottle XDG disable
declare -r GC_BTL_XDG_ENB=1				# Bottle XDG enable

# Global Variable Array Indexes
# -----------------------------
declare -r E_GLBL_ROOT=0					# Wine Manager data directory environment
declare -r E_GLBL_XDG_PRI_HOST=1			# Private XDG root directory environment variable
declare -r E_GLBL_XDG_HOST_MUX=2			# Host XDG Mux
declare -r E_GLBL_XDG_REFRESH=3			# Wine custom Host XDG refresh command
declare -r E_GLBL_VERBOSE=4				# Verbose output flag
declare -r E_GLBL_ENV_VAR_ARY_SIZE=5	# Environment variable array size
declare -r E_GLBL_TOK_ARY_SIZE=6			# Token array size
declare -r E_GLBL_CVAR_WMP_ARY_SIZE=7	# Protected Wine Manager conf variable array size
declare -r E_GLBL_CVAR_WMW_ARY_SIZE=8	# Wine Manager conf variable array size
declare -r E_GLBL_CVAR_BTLP_ARY_SIZE=9	# Proected bottle conf variable array size
declare -r E_GLBL_CVAR_BTLW_ARY_SIZE=10	# Bottle conf variable array size
declare -r E_GLBL_ROOT_DIR_ARY_SIZE=11	# Root directory array size
declare -r E_GLBL_BTL_DIR_ARY_SIZE=12	# Bottle directory array size
declare -r E_GLBL_MNTPNT_ARY_SIZE=13	# Mount point array size
declare -r E_GLBL_STR_USAGE=14			# Usage string
declare -r E_GLBL_STR_HELP=15				# Help string
declare -r E_GLBL_MSG_ARY_IDX=16			# Current message array index
declare -r E_GLBL_MSG_ARY_NAME=17		# Message array name
declare -r E_GLBL_ERR_CODE=18				# Last error code

# Strings Array Indexes
# ---------------------
declare -r E_STR_CMD_APPEND=0				# Append command
declare -r E_STR_CMD_BACKUP=1				# Backup command
declare -r E_STR_CMD_CHANGE=2				# Change command
declare -r E_STR_CMD_CONF=3				# Configure command
declare -r E_STR_CMD_CONSOLE=4			# Console command
declare -r E_STR_CMD_CREATE=5				# Create command
declare -r E_STR_CMD_DEFAULT=6			# Default command
declare -r E_STR_CMD_DEINIT=7				# Deinitialize command
declare -r E_STR_CMD_DELETE=8				# Delete command
declare -r E_STR_CMD_EDIT=9				# Edit command
declare -r E_STR_CMD_HELP=10				# Help command
declare -r E_STR_CMD_INIT=11				# Initialize command
declare -r E_STR_CMD_INSTANTIATE=12		# Instantiate command
declare -r E_STR_CMD_LIST=13				# List command
declare -r E_STR_CMD_MIGRATE=14			# Migrate command
declare -r E_STR_CMD_REFRESH=15			# Refresh command
declare -r E_STR_CMD_RESTORE=16			# Restore command
declare -r E_STR_CMD_VERSION=17			# Version command
declare -r E_STR_CMD_XDG=18				# XDG command
declare -r E_STR_CMD_ARG_BACKUP=19		# Backup command argument
declare -r E_STR_CMD_ARG_BOTTLE=20		# Bottle command argument
declare -r E_STR_CMD_ARG_MANAGER=21		# Wine manager command argument

declare -r E_STR_CMD_ARG_RD=22			# Read command argument
declare -r E_STR_CMD_ARG_WR=23			# Write command argument
declare -r E_STR_CMD_ARG_DEL=24			# Delete command argument
declare -r E_STR_CMD_ARG_HELP=25			# Help command argument

declare -r E_STR_TOKSTR_CMD=26			# Command token string
declare -r E_STR_TOKSTR_ENV=27			# Environment token string 
declare -r E_STR_TOKSTR_BTL=28			# Bottle name token string
declare -r E_STR_TOKSTR_MODE=29			# Mode token string
declare -r E_STR_TOKSTR_OPT=30			# Option token string
declare -r E_STR_TOKSTR_SUBMENU=31		# Submenu token string
declare -r E_STR_TOKSTR_SUB_DIR=32		# Subdirectory token string
declare -r E_STR_TOKSTR_WINE_VER=33		# Wine version token string
declare -r E_STR_TOKSTR_NAME=34			# New name token string
declare -r E_STR_TOKSTR_OLD_VAL=35		# Old value token string
declare -r E_STR_TOKSTR_VAL=36			# New value token string
declare -r E_STR_TOKSTR_MINVFY=37		# Minimum verify token string
declare -r E_STR_TOKSTR_FORCE=38			# Force token string
declare -r E_STR_WM_BTL_BCKP_DIR=39		# Wine Manager bottle backup directory
declare -r E_STR_WM_BIN_DIR=40			# Wine Manager bin directory
declare -r E_STR_WM_BTL_DIR=41			# Wine Manager bottle directory
declare -r E_STR_WM_RSRC_DIR=42			# Wine Manager resource directory
declare -r E_STR_WM_SRVC_DIR=43			# Wine Manager service directory
declare -r E_STR_WM_TMP_DIR=44			# Wine Manager Temporary directory
declare -r E_STR_WM_BTL_TMPLT_DIR=45	# Wine Manager bottle template directory
declare -r E_STR_WM_CONF_FILE=46			# Wine Manager config file
declare -r E_STR_WM_MON_NAME=47			# XDG Monitor name
declare -r E_STR_WM_MON_SRVC_NAME=48	# XDG Monitor service file name
declare -r E_STR_WM_MON_SRVC_FILE=49	# XDG Monitor service file pathname
declare -r E_STR_WM_MON_BIN_NAME=50		# XDG Monitor binary file name
declare -r E_STR_WM_MON_BIN_FILE=51		# XDG Monitor binary file pathname
declare -r E_STR_WM_XFCE_DSKTP_FILE=52	# Dummy XFCE desktop file
declare -r E_STR_WM_SYS_EXT=53			# Wine Manager system bottle extension
declare -r E_STR_WM_SYS_BTL_NAME=54		# Wine Manager system bottle name
declare -r E_STR_WM_SYS_MENU_NAME=55	# Wine Manager system bottle menu name
declare -r E_STR_BTL_BIN_DIR=56			# Bottle bin directory
declare -r E_STR_BTL_WINE_VER=56			# Bottle wine version
declare -r E_STR_BTL_XDG_DIR=57			# Bottle XDG directory
declare -r E_STR_BTL_CONF_FILE=58		# Bottle config file name
declare -r E_STR_BTL_ENV_FILE_NAME=60	# Bottle environment file name
declare -r E_STR_DFLT_WINE_LINK=61		# Default wine version link
declare -r E_STR_KEY_WM_ID=62				# Wine Manager ID key
declare -r E_STR_KEY_WM_INIT=63			# Initialized state key key
declare -r E_STR_KEY_BTL_DFLT=64			# Default bottle key
declare -r E_STR_KEY_BTL_WINEDIR=65		# Bottle wine version key
declare -r E_STR_KEY_BTL_ENVSCR=66		# Bottle environment enable key
declare -r E_STR_KEY_BTL_SMENU=67		# Bottle submenu key
declare -r E_STR_KEY_BTL_XDG_ENB=68		# Bottle XDG enable key
declare -r E_STR_MSG_LBL_ERR=69			# Error message label
declare -r E_STR_MSG_LBLSPC_ERR=70		# Error message label spaces
declare -r E_STR_MSG_LBL_WARN=71			# Warning message label
declare -r E_STR_MSG_LBLSPC_WARN=72		# Warning message label spaces
declare -r E_STR_MSG_LBL_INFO=73			# Info message label
declare -r E_STR_MSG_LBLSPC_INFO=74		# Info message label spaces
declare -r E_STR_MSG_LBL_USAGE=75		# Usage message label
declare -r E_STR_MSG_LBLSPC_USAGE=76	# Usage message label spaces
declare -r E_STR_MSG_LBL_HELP=77			# Usage message label
declare -r E_STR_MSG_LBLSPC_HELP=78		# Usage message label spaces

# XDG Directory Array Indexes
# ---------------------------
declare -r E_XDG_PRI_BOTTLE=1
declare -r E_XDG_BOTTLE_MUX=2
declare -r E_XDG_PRI_BOTTLE_TRANS=3
declare -r E_XDG_BOTTLE_TO_BOTTLE=4

# Syntax Array Indexes
# --------------------
declare -r E_SYTX_APPEND=0
declare -r E_SYTX_BACKUP=1
declare -r E_SYTX_CONF=2
declare -r E_SYTX_CONSOLE=3
declare -r E_SYTX_CHANGE=4
declare -r E_SYTX_CREATE=5
declare -r E_SYTX_DEFAULT=6
declare -r E_SYTX_DEINIT=7
declare -r E_SYTX_DELETE=8
declare -r E_SYTX_EDIT=9
declare -r E_SYTX_INIT=10
declare -r E_SYTX_INSTANTIATE=11
declare -r E_SYTX_LIST=12
declare -r E_SYTX_XDG=13
declare -r E_SYTX_MIGRATE=14
declare -r E_SYTX_REFRESH=15
declare -r E_SYTX_RESTORE=16
declare -r E_SYTX_VERSION=17
declare -r E_SYTX_HELP=18

# Usage Array Indexes
# -------------------
declare -r E_USG_APPEND=0
declare -r E_USG_BACKUP=1
declare -r E_USG_CONF=2
declare -r E_USG_CONSOLE=3
declare -r E_USG_CHANGE=4
declare -r E_USG_CREATE=5
declare -r E_USG_DEFAULT=6
declare -r E_USG_DEINIT=7
declare -r E_USG_DELETE=8
declare -r E_USG_EDIT=9
declare -r E_USG_INIT=10
declare -r E_USG_INSTANTIATE=11
declare -r E_USG_LIST=12
declare -r E_USG_XDG=13
declare -r E_USG_MIGRATE=14
declare -r E_USG_REFRESH=15
declare -r E_USG_RESTORE=16
declare -r E_USG_VERSION=17
declare -r E_USG_HELP=18

# Help Array Indexes
# -------------------
declare -r E_HLP_APPEND=0
declare -r E_HLP_BACKUP=1
declare -r E_HLP_CONF=2
declare -r E_HLP_CONSOLE=3
declare -r E_HLP_CHANGE=4
declare -r E_HLP_CREATE=5
declare -r E_HLP_DEFAULT=6
declare -r E_HLP_DEINIT=7
declare -r E_HLP_DELETE=8
declare -r E_HLP_EDIT=9
declare -r E_HLP_INIT=10
declare -r E_HLP_INSTANTIATE=11
declare -r E_HLP_LIST=12
declare -r E_HLP_XDG=13
declare -r E_HLP_MIGRATE=14
declare -r E_HLP_REFRESH=15
declare -r E_HLP_RESTORE=16
declare -r E_HLP_VERSION=17
declare -r E_HLP_HELP=18
declare -r E_HLP_ALL=19

# Token Parser Variable Indexes
# -----------------------------
declare -r E_TOK_NUM_TOKS=0
declare -r E_TOK_LAST_II=1
declare -r E_TOK_LAST_PI=2
declare -r E_TOK_LAST_AI=3
		
declare -r E_TOK_CMD=4						# Command argument
declare -r E_TOK_ENV=5						# Environment file argument
declare -r E_TOK_BTL=6						# Bottle name argument
declare -r E_TOK_VAL=7					# New value argument
declare -r E_TOK_MODE=8						# Option argument
declare -r E_TOK_OPT=9						# Option argument
declare -r E_TOK_OLD_VAL=10				# Old value argument
declare -r E_TOK_SUBMENU=11				# Submenu argument
declare -r E_TOK_SUB_DIR=12				# Subdirectory argument
declare -r E_TOK_WINE_VER=13				# Wine version argument
declare -r E_TOK_NAME=14					# New name argument

declare -r E_TOK_CMDF=15					# Command found
declare -r E_TOK_ENVF=16					# Environment file found
declare -r E_TOK_BTLF=17					# Bottle name found
declare -r E_TOK_VALF=18				# New value found
declare -r E_TOK_MODEF=19					# Mode found
declare -r E_TOK_OPTF=20					# Option found
declare -r E_TOK_OLD_VALF=21				# Old value found
declare -r E_TOK_SUBMENUF=22				# Submenu found
declare -r E_TOK_SUB_DIRF=23				# Subdirectory found
declare -r E_TOK_WINE_VERF=24				# Wine version found
declare -r E_TOK_NAMEF=25					# New name found
declare -r E_TOK_MINVFYF=26				# Minimum verify command found (doesn't have arguments)
declare -r E_TOK_FORCEF=27					# Force command found (doesn't have arguments)


# -------------------------
# Script Specific Variables
# -------------------------

G_MSG_EXIT=""

G_TMP_ANSWER=""
G_TMP_ARY=()
G_TMP_ARY2=()
G_TMP_ARY3=()
G_TMP_ARY4=()
G_TMP_BTL_NAME=""
G_TMP_BTL_DIR=""
G_TMP_BTL_PATHNAME=""
G_TMP_BTL_CONF_FILE=""
G_TMP_BTL_ENV_FILE=""
G_TMP_CONF_PATHNAME=""
G_TMP_DIR_NAME=""
G_TMP_DIR_DEST=""
G_TMP_EXEC_NAME=""
G_TMP_FILE_NAME=""
G_TMP_FLAG=0
G_TMP_IFS=""
G_TMP_INT=0
G_TMP_LNK_NAME=""
G_TMP_MODE=""
G_TMP_OPT=""
G_TMP_STR=""
G_TMP_STAT=0
G_TMP_SUBDIR=""
G_TMP_TOK_INV=""
G_TMP_WINEDIR_NAME=""
G_TMP_WRK_BTL_NAME=""
G_TMP_WRK_BTL_PATHNAME=""

#
# ~~~~~~~~~~~~~~~~~~~~
# Message Array Values
# ~~~~~~~~~~~~~~~~~~~~
#
declare -a G_MSG_ARY=()						# Message Array
declare -r GC_MSG_CODE_TRM="^"			# Message code terminator character
declare -r GC_SEP_SYSD_UNIT="^"			# SystemD Unit Name field seperator character
declare -r GC_SEP_FTRC=":: "				# Function trace seperator character

declare -r GC_MSGT_NONE=0					# No message type
declare -r GC_MSGT_ERR_CODE=1				# Error code message type
declare -r GC_MSGT_ERR=2					# Error string message type
declare -r GC_MSGT_HELP=3					# Help message type
declare -r GC_MSGT_INFO=4					# Information message type
declare -r GC_MSGT_SUCCESS=5				# Success message type
declare -r GC_MSGT_USAGE=6					# Usage message type
declare -r GC_MSGT_WARN=7					# Warning message type


#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Wine Manager Global Variable Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
declare -a G_GLBL_VAR_ARY								# Variable Array
																# Wine Manager root directory
G_GLBL_VAR_ARY[$E_GLBL_ROOT]="`echo "$WINEMGR_ROOT" | sed 's#/$##'`"
																# Host private XDG root directory
G_GLBL_VAR_ARY[$E_GLBL_XDG_PRI_HOST]="`echo "$WINEMGR_XDG_HOST" | sed 's#/$##'`"
																# Host XDG Mux
G_GLBL_VAR_ARY[$E_GLBL_XDG_HOST_MUX]="`echo "$WINEMGR_XDG_HOST_MUX" | sed 's#/$##'`"
																# Custom Host XDG refresh command
G_GLBL_VAR_ARY[$E_GLBL_XDG_REFRESH]="`echo "$WINEMGR_XDG_REFRESH" | sed 's#/$##'`"
G_GLBL_VAR_ARY[$E_GLBL_VERBOSE]=0					# Verbose output flag
G_GLBL_VAR_ARY[$E_GLBL_TOK_ARY_SIZE]=0				# Token array size
G_GLBL_VAR_ARY[$E_GLBL_ROOT_DIR_ARY_SIZE]=0		# Root directory array size
G_GLBL_VAR_ARY[$E_GLBL_BTL_DIR_ARY_SIZE]=0		# Bottle directory array size
G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]=""				# Usage string
G_GLBL_VAR_ARY[$E_GLBL_STR_HELP]=""					# Help string
G_GLBL_VAR_ARY[$E_GLBL_MSG_ARY_IDX]=-1				# Current message array index
G_GLBL_VAR_ARY[$E_GLBL_MSG_ARY_NAME]=G_MSG_ARY	# Message array name
G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]=$WM_ERR_NONE	# Last error code

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Error Message Constants Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
declare -a GC_ERR_MSG_ARY							# Constant Array

GC_ERR_MSG_ARY[$WM_ERR_NONE]="No error"
GC_ERR_MSG_ARY[$WM_ERR_INV_RESP]="Invalid response"
GC_ERR_MSG_ARY[$WM_ERR_SRVC_START]="Service start failed"
GC_ERR_MSG_ARY[$WM_ERR_SRVC_STOP]="Service stop failed"
GC_ERR_MSG_ARY[$WM_ERR_SRVC_DSB]="Service disable failed"
GC_ERR_MSG_ARY[$WM_ERR_SRVC_RELD]="Service reload failed"
GC_ERR_MSG_ARY[$WM_ERR_BTL_NEXIST]="Bottle doesn't exist"
GC_ERR_MSG_ARY[$WM_ERR_BTL_EXISTS]="Bottle already exists"
GC_ERR_MSG_ARY[$WM_ERR_BTL_NNAME]="No bottle name"
GC_ERR_MSG_ARY[$WM_ERR_BTL_ISDFLT]="Bottle can't be accessed because its the default"
GC_ERR_MSG_ARY[$WM_ERR_BTL_XDGENB]="Bottle can't be accessed because its XDG is enabled"
GC_ERR_MSG_ARY[$WM_ERR_BTL_SYS]="System bottles cannot be accessed or modified"
GC_ERR_MSG_ARY[$WM_ERR_DIR_NEXIST]="Directory doesn't exist"
GC_ERR_MSG_ARY[$WM_ERR_DIR_EXISTS]="Directory already exists"
GC_ERR_MSG_ARY[$WM_ERR_DIR_RD]="Directory not readable"
GC_ERR_MSG_ARY[$WM_ERR_DIR_WR]="Directory not writeable"
GC_ERR_MSG_ARY[$WM_ERR_DIR_RW]="Directory not read/write"
GC_ERR_MSG_ARY[$WM_ERR_DIR_CREATE]="Directory create failed"
GC_ERR_MSG_ARY[$WM_ERR_DIR_COPY]="Directory copy failed"
GC_ERR_MSG_ARY[$WM_ERR_DIR_MOVE]="Directory move failed"
GC_ERR_MSG_ARY[$WM_ERR_BTL_RENAME]="Bottle rename failed"
GC_ERR_MSG_ARY[$WM_ERR_DIR_DEL]="Directory delete failed"
GC_ERR_MSG_ARY[$WM_ERR_DIR_NMERGE]="Not a merger file system"
GC_ERR_MSG_ARY[$WM_ERR_LNK_NEXIST]="Link doesn't exist"
GC_ERR_MSG_ARY[$WM_ERR_LNK_EXISTS]="Link already exists"
GC_ERR_MSG_ARY[$WM_ERR_LNK_CREATE]="Link create failed"
GC_ERR_MSG_ARY[$WM_ERR_LNK_DEL]="Link delete failed"
GC_ERR_MSG_ARY[$WM_ERR_FILE_CREATE]="File create failed"
GC_ERR_MSG_ARY[$WM_ERR_FILE_COPY]="File copy failed"
GC_ERR_MSG_ARY[$WM_ERR_FILE_MOVE]="File move failed"
GC_ERR_MSG_ARY[$WM_ERR_FILE_DEL]="File delete failed"
GC_ERR_MSG_ARY[$WM_ERR_FILE_NEXIST]="File doesn't exist"
GC_ERR_MSG_ARY[$WM_ERR_FILE_EXISTS]="File already exists"
GC_ERR_MSG_ARY[$WM_ERR_FILE_RD]="File not readable"
GC_ERR_MSG_ARY[$WM_ERR_FILE_WR]="File not writeable"
GC_ERR_MSG_ARY[$WM_ERR_FILE_RW]="File not read/write"
GC_ERR_MSG_ARY[$WM_ERR_FILE_NEXEC]="File not executable"
GC_ERR_MSG_ARY[$WM_ERR_ENV_NEXIST]="Environment variable doesn't exist"
GC_ERR_MSG_ARY[$WM_ERR_CVAR_EXIST]="Configuration variable already exists"
GC_ERR_MSG_ARY[$WM_ERR_CVAR_NEXIST]="Configuration variable doesn't exist"
GC_ERR_MSG_ARY[$WM_ERR_CVAR_RD]="Configuration variable not readable"
GC_ERR_MSG_ARY[$WM_ERR_CVAR_WR]="Configuration variable not writeable"
GC_ERR_MSG_ARY[$WM_ERR_CVAR_RW]="Configuration variable not read/write"
GC_ERR_MSG_ARY[$WM_ERR_CVAR_DEL]="Configuration variable cannot be deleted"
GC_ERR_MSG_ARY[$WM_ERR_CVAR_INVVAL]="Configuration variable value is invalid"
GC_ERR_MSG_ARY[$WM_ERR_XDG_ENB]="Host XDG already enabled"
GC_ERR_MSG_ARY[$WM_ERR_XDG_DSB]="Host XDG already disabled"
GC_ERR_MSG_ARY[$WM_ERR_PARM_INV]="Invalid parameter"
GC_ERR_MSG_ARY[$WM_ERR_PARM_MISS]="Mandatory parameter missing"
GC_ERR_MSG_ARY[$WM_ERR_UNK_FD_TYPE]="Unknown directory/file type"
GC_ERR_MSG_ARY[$WM_ERR_UNK_CMD]="Unrecognized command"
GC_ERR_MSG_ARY[$WM_ERR_UNK_ARG]="Unrecognized argument"
GC_ERR_MSG_ARY[$WM_ERR_UNK_MODE]="Unrecognized mode"
GC_ERR_MSG_ARY[$WM_ERR_UNK_OPT]="Unrecognized option"
GC_ERR_MSG_ARY[$WM_ERR_NUM_ARGS]="Incorrect number of arguments"
GC_ERR_MSG_ARY[$WM_ERR_NO_CMD]="No command"
GC_ERR_MSG_ARY[$WM_ERR_INIT]="Wine Manager must be initialized"
GC_ERR_MSG_ARY[$WM_ERR_DEINIT]="Wine Manager must be deinitialized"
GC_ERR_MSG_ARY[$WM_ERR_RFRSH_XDG]="XDG refresh command failed"

readonly -a GC_ERR_MSG_ARY

#
# ~~~~~~~~~~~~~~~~~~~~~~
# String Constants Array
# ~~~~~~~~~~~~~~~~~~~~~~
#
declare -a GC_STR_ARY										# Constant Array

GC_STR_ARY[$E_STR_CMD_APPEND]="append"					# Append command
GC_STR_ARY[$E_STR_CMD_BACKUP]="backup"					# Backup command
GC_STR_ARY[$E_STR_CMD_CHANGE]="change"					# Change command
GC_STR_ARY[$E_STR_CMD_CONF]="conf"						# Configure command
GC_STR_ARY[$E_STR_CMD_CONSOLE]="console"				# Console command
GC_STR_ARY[$E_STR_CMD_CREATE]="create"					# Create command
GC_STR_ARY[$E_STR_CMD_DEFAULT]="default"				# Default command
GC_STR_ARY[$E_STR_CMD_DEINIT]="deinit"					# Deinitialize command
GC_STR_ARY[$E_STR_CMD_DELETE]="delete"					# Delete command
GC_STR_ARY[$E_STR_CMD_EDIT]="edit"						# Edit command
GC_STR_ARY[$E_STR_CMD_HELP]="help"						# Help command
GC_STR_ARY[$E_STR_CMD_INIT]="init"						# Initialize command
GC_STR_ARY[$E_STR_CMD_INSTANTIATE]="instantiate"	# Instantiate command
GC_STR_ARY[$E_STR_CMD_LIST]="list"						# List command
GC_STR_ARY[$E_STR_CMD_MIGRATE]="migrate"				# Migrate command
GC_STR_ARY[$E_STR_CMD_REFRESH]="refresh"				# Refresh command
GC_STR_ARY[$E_STR_CMD_RESTORE]="restore"				# Restore command
GC_STR_ARY[$E_STR_CMD_VERSION]="version"				# Version command
GC_STR_ARY[$E_STR_CMD_XDG]="xdg"							# XDG command
GC_STR_ARY[$E_STR_CMD_ARG_BACKUP]="backup"			# Backup command argument
GC_STR_ARY[$E_STR_CMD_ARG_BOTTLE]="bottle"			# Bottle command argument
GC_STR_ARY[$E_STR_CMD_ARG_MANAGER]="manager"			# Wine manager command argument
GC_STR_ARY[$E_STR_CMD_ARG_RD]="rd"						# Read command argument
GC_STR_ARY[$E_STR_CMD_ARG_WR]="wr"						# Write command argument
GC_STR_ARY[$E_STR_CMD_ARG_DEL]="del"					# Delete command argument
GC_STR_ARY[$E_STR_CMD_ARG_HELP]="help"					# Help command argument
GC_STR_ARY[$E_STR_TOKSTR_CMD]="-wmcmd"
GC_STR_ARY[$E_STR_TOKSTR_ENV]="-env"
GC_STR_ARY[$E_STR_TOKSTR_BTL]="-b"
GC_STR_ARY[$E_STR_TOKSTR_MODE]="-mode"
GC_STR_ARY[$E_STR_TOKSTR_OPT]="-op"
GC_STR_ARY[$E_STR_TOKSTR_SUBMENU]="-submenu"
GC_STR_ARY[$E_STR_TOKSTR_SUB_DIR]="-subdir"
GC_STR_ARY[$E_STR_TOKSTR_WINE_VER]="-ver"
GC_STR_ARY[$E_STR_TOKSTR_NAME]="-name"
GC_STR_ARY[$E_STR_TOKSTR_OLD_VAL]="-oval"
GC_STR_ARY[$E_STR_TOKSTR_VAL]="-val"
GC_STR_ARY[$E_STR_TOKSTR_MINVFY]="-mv"
GC_STR_ARY[$E_STR_TOKSTR_FORCE]="-f"
GC_STR_ARY[$E_STR_WM_BTL_BCKP_DIR]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/backup"
GC_STR_ARY[$E_STR_WM_BIN_DIR]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/bin"
GC_STR_ARY[$E_STR_WM_BTL_DIR]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/btl"
GC_STR_ARY[$E_STR_WM_RSRC_DIR]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/resource"
GC_STR_ARY[$E_STR_WM_SRVC_DIR]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/service"
GC_STR_ARY[$E_STR_WM_TMP_DIR]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/tmp"
GC_STR_ARY[$E_STR_WM_BTL_TMPLT_DIR]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/bottle_template"
GC_STR_ARY[$E_STR_WM_CONF_FILE]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/config_wm"
GC_STR_ARY[$E_STR_WM_MON_NAME]="wm_xdg_monitor"
GC_STR_ARY[$E_STR_WM_MON_SRVC_NAME]="${GC_STR_ARY[$E_STR_WM_MON_NAME]}@.service"
GC_STR_ARY[$E_STR_WM_MON_SRVC_FILE]="${GC_STR_ARY[$E_STR_WM_SRVC_DIR]}/${GC_STR_ARY[$E_STR_WM_MON_SRVC_NAME]}"
GC_STR_ARY[$E_STR_WM_MON_BIN_NAME]="${GC_STR_ARY[$E_STR_WM_MON_NAME]}.sh"
GC_STR_ARY[$E_STR_WM_MON_BIN_FILE]="${GC_STR_ARY[$E_STR_WM_BIN_DIR]}/${GC_STR_ARY[$E_STR_WM_MON_BIN_NAME]}"
GC_STR_ARY[$E_STR_WM_XFCE_DSKTP_FILE]="${GC_STR_ARY[$E_STR_WM_RSRC_DIR]}/wine-manager-dummy.desktop"
GC_STR_ARY[$E_STR_WM_SYS_EXT]="wmsys"					# Wine Manager system bottle extension
																	# Wine Manager system bottle name
GC_STR_ARY[$E_STR_WM_SYS_BTL_NAME]="winemanager.${GC_STR_ARY[$E_STR_WM_SYS_EXT]}"
GC_STR_ARY[$E_STR_WM_SYS_MENU_NAME]="Wine Manager"	# Wine Manager system bottle menu name
GC_STR_ARY[$E_STR_BTL_BIN_DIR]="bin"
GC_STR_ARY[$E_STR_BTL_WINE_VER]="wine"
GC_STR_ARY[$E_STR_BTL_XDG_DIR]="xdg"
GC_STR_ARY[$E_STR_BTL_CONF_FILE]="config_btl"
GC_STR_ARY[$E_STR_BTL_ENV_FILE_NAME]="env.sh"
GC_STR_ARY[$E_STR_DFLT_WINE_LINK]="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}/wine_dflt"
GC_STR_ARY[$E_STR_KEY_WM_ID]="WmID"						# Wine Manager ID key
GC_STR_ARY[$E_STR_KEY_WM_INIT]="Init"					# Initialized state key key
GC_STR_ARY[$E_STR_KEY_BTL_DFLT]="DefaultBottle"		# Default wine bottle key
GC_STR_ARY[$E_STR_KEY_BTL_WINEDIR]="WineDir"			# Bottle wine version key
GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]="EnvScr"			# Bottle environment script key
GC_STR_ARY[$E_STR_KEY_BTL_SMENU]="Submenu"			# Bottle submenu key
GC_STR_ARY[$E_STR_KEY_BTL_XDG_ENB]="XdgEnb"			# Bottle XDG enable key

GC_STR_ARY[$E_STR_MSG_LBL_ERR]="ERROR: "				# Error message label
																	# Error message label space string
GC_STR_ARY[$E_STR_MSG_LBLSPC_ERR]=`eval $(echo printf '" %0.s"' {1..${#GC_STR_ARY[$E_STR_MSG_LBL_ERR]}})`

GC_STR_ARY[$E_STR_MSG_LBL_WARN]="WARNING: "			# Warning message label
																	# Warning message label space string
GC_STR_ARY[$E_STR_MSG_LBLSPC_WARN]=`eval $(echo printf '" %0.s"' {1..${#GC_STR_ARY[$E_STR_MSG_LBL_WARN]}})`

GC_STR_ARY[$E_STR_MSG_LBL_INFO]="INFO: "				# Info message label
																	# Info message label space string
GC_STR_ARY[$E_STR_MSG_LBLSPC_INFO]=`eval $(echo printf '" %0.s"' {1..${#GC_STR_ARY[$E_STR_MSG_LBL_INFO]}})`

GC_STR_ARY[$E_STR_MSG_LBL_USAGE]="USAGE: "			# Usage message label
																	# Usage message label space string
GC_STR_ARY[$E_STR_MSG_LBLSPC_USAGE]=`eval $(echo printf '" %0.s"' {1..${#GC_STR_ARY[$E_STR_MSG_LBL_USAGE]}})`

GC_STR_ARY[$E_STR_MSG_LBL_HELP]="HELP: "				# Help message label
																	# Help message label space string
GC_STR_ARY[$E_STR_MSG_LBLSPC_HELP]=`eval $(echo printf '" %0.s"' {1..${#GC_STR_ARY[$E_STR_MSG_LBL_HELP]}})`

readonly -a GC_STR_ARY

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XDG Directory Constant Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
declare -a GC_XDG_DIR_ARY								# Constant Array

GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]="xdg/pri_bottle"
GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]="xdg/bottle_mux"
GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE_TRANS]="xdg/pri_bottle_translate"
GC_XDG_DIR_ARY[$E_XDG_BOTTLE_TO_BOTTLE]="${GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]}"

readonly -a GC_XDG_DIR_ARY

# ~~~~~~~~~~~~~~~~~~~~~~~~~~
# XDG Subpath Constant Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
#
declare -ar GC_XDG_SUBPATH_ARY=(
	"Desktop"
	".config/menus"
	".local/share/applications"
	".local/share/desktop-directories"
	".local/share/icons"
	".local/share/mime"
)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XDG Desktop File Subpath Constant Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
declare -ar GC_XDG_DSKTP_SUBPATH_ARY=(
	"Desktop"
	".local/share/applications"
)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Environment Variable Constant Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
declare -r GC_EV_ELM_1=("WINEMGR_ROOT" "pm"  "Wine Manager root directory")
declare -r GC_EV_ELM_2=("WINEMGR_DWINE_PATH" "pm"  "Default wine version")
declare -r GC_EV_ELM_3=("WINEMGR_XDG_HOST" "dm" "Host XDG root directory")
declare -r GC_EV_ELM_4=("WINEMGR_XDG_HOST_MUX" "dm"  "Host XDG multiplexer root directory")
declare -r GC_EV_ELM_5=("WINESERVER" "pm"  "Default wine server executable")
declare -r GC_EV_ELM_6=("WINELOADER" "pm"  "Default wine executable")
declare -r GC_EV_ELM_7=("WINEDLLPATH" "pm"  "Default wine DLL path")
declare -r GC_EV_ELM_8=("WINEMGR_XDG_REFRESH" "xo"  "Optional XDG refresh command")

declare -ar GC_ENV_VAR_ARY=(
   GC_EV_ELM_1[@]
   GC_EV_ELM_2[@]
   GC_EV_ELM_3[@]
   GC_EV_ELM_4[@]
   GC_EV_ELM_5[@]
   GC_EV_ELM_6[@]
   GC_EV_ELM_7[@]
   GC_EV_ELM_8[@]
)

G_GLBL_VAR_ARY[$E_GLBL_ENV_VAR_ARY_SIZE]=${#GC_ENV_VAR_ARY[@]}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configuration Variable Constants
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Configuration Variable Types
# ----------------------------
declare -r GC_CVAR_TYPE_WMP=0							# Protected Window Manager
declare -r GC_CVAR_TYPE_WMW=1							# Writable Window Manager
declare -r GC_CVAR_TYPE_BTLP=2						# Protected Bottle
declare -r GC_CVAR_TYPE_BTLW=3						# Writable Bottle
declare -r GC_CVAR_TYPE_USERWM=4						# User Window Manager
declare -r GC_CVAR_TYPE_USERBTL=5					# User Bottle

# Variable Type Check Function Return Status
# ------------------------------------------
declare -r GC_FUNCS_VarTypeChk_P=0					# Protected variable
declare -r GC_FUNCS_VarTypeChk_W=1					# Writable variable
declare -r GC_FUNCS_VarTypeChk_U=2					# User variable


# 
# Element Format: Variable Name, Value Array Name, Description
# Value Array Format: Valid values or "*" for any value valid
#
# Wine Manager Protected Configuration Variables Array
# ----------------------------------------------------
#
declare GC_WMCP_ELM_1=("${GC_STR_ARY[$E_STR_KEY_WM_ID]}" "GC_WMCP_VAL_ARY_1" "Wine Manager ID")
declare GC_WMCP_VAL_ARY_1=("")

declare GC_WMCP_ELM_2=("${GC_STR_ARY[$E_STR_KEY_WM_INIT]}" "GC_WMCP_VAL_ARY_2" "Wine Manager Initialized State")
declare GC_WMCP_VAL_ARY_2=("0" "1")

declare GC_WMCP_ELM_3=("${GC_STR_ARY[$E_STR_KEY_BTL_DFLT]}" "GC_WMCP_VAL_ARY_3" "Default Host Bottle")
declare GC_WMCP_VAL_ARY_3=("*")

# Array
# ~~~~~
declare -a GC_CVAR_WMP_ARY=(
   GC_WMCP_ELM_1[@]
   GC_WMCP_ELM_2[@]
   GC_WMCP_ELM_3[@]
)
readonly -a GC_CVAR_WMP_ARY

G_GLBL_VAR_ARY[$E_GLBL_CVAR_WMP_ARY_SIZE]=${#GC_CVAR_WMP_ARY[@]}


#
# Wine Manager Writable Configuration Variables Array
# ---------------------------------------------------
#
declare GC_WMCW_ELM_1=("WmDummy1" "GC_WMCW_VAL_ARY_1" "User Wine Manager Configuration Variable - Dummy 1")
declare GC_WMCW_VAL_ARY_1=("GlblDummy1_Val1"  "GlblDummy1_Val2" "GlblDummy1_Val3")

declare GC_WMCW_ELM_2=("WmDummy2" "GC_WMCW_VAL_ARY_2" "User Wine Manager Configuration Variable - Dummy 2")
declare GC_WMCW_VAL_ARY_2=("*")

# Array
# ~~~~~
declare -a GC_CVAR_WMW_ARY=(
   GC_WMCW_ELM_1[@]
   GC_WMCW_ELM_2[@]
)
readonly -a GC_CVAR_WMW_ARY

G_GLBL_VAR_ARY[$E_GLBL_CVAR_WMW_ARY_SIZE]=${#GC_CVAR_WMW_ARY[@]}


#
# Bottle Protected Configuration Variables Array
# ----------------------------------------------
#
declare GC_BCP_ELM_1=("${GC_STR_ARY[$E_STR_KEY_BTL_WINEDIR]}" "GC_BCP_VAL_ARY_1" "Wine directory")
declare GC_BCP_VAL_ARY_1=("*")

declare GC_BCP_ELM_2=("${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}" "GC_BCP_VAL_ARY_2" "Environment script")
declare GC_BCP_VAL_ARY_2=("*")

declare GC_BCP_ELM_3=("${GC_STR_ARY[$E_STR_KEY_BTL_SMENU]}" "GC_BCP_VAL_ARY_3" "Submenu")
declare GC_BCP_VAL_ARY_3=("*")

declare GC_BCP_ELM_4=("${GC_STR_ARY[$E_STR_KEY_BTL_XDG_ENB]}" "GC_BCP_VAL_ARY_4" "XDG enable")
declare GC_BCP_VAL_ARY_4=("0" "1")

# Array
# ~~~~~
declare -a GC_CVAR_BTLP_ARY=(
   GC_BCP_ELM_1[@]
   GC_BCP_ELM_2[@]
   GC_BCP_ELM_3[@]
   GC_BCP_ELM_4[@]
)
readonly -a GC_CVAR_BTLP_ARY

G_GLBL_VAR_ARY[$E_GLBL_CVAR_BTLP_ARY_SIZE]=${#GC_CVAR_BTLP_ARY[@]}


#
# Bottle Writable Configuration Variables Array
# ---------------------------------------------
#
declare GC_BCW_ELM_1=("DesktopIcon" "GC_BCW_VAL_ARY_1" "Desktop Icon Enable")
declare GC_BCW_VAL_ARY_1=("enable" "disable")

declare GC_BCW_ELM_2=("BtlDummy1" "GC_BCW_VAL_ARY_2" "Bottle Variable - Dummy 1")
declare GC_BCW_VAL_ARY_2=("BtlDummy1_Val1" "BtlDummy1_Val2" "BtlDummy1_Val3")

declare GC_BCW_ELM_3=("BtlDummy2" "GC_BCW_VAL_ARY_3" "Bottle Variable - Dummy 2")
declare GC_BCW_VAL_ARY_3=("BtlDummy2_Val1")

# Array
# ~~~~~
declare -a GC_CVAR_BTLW_ARY=(
   GC_BCW_ELM_1[@]
   GC_BCW_ELM_2[@]
   GC_BCW_ELM_3[@]
)
readonly -a GC_CVAR_BTLW_ARY

G_GLBL_VAR_ARY[$E_GLBL_CVAR_BTLW_ARY_SIZE]=${#GC_CVAR_BTLW_ARY[@]}


#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Root Directory Constant Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Elements
# ~~~~~~~~
# Format: Dir/File Name, Dir/File type, Description
#
# Root Values
declare -r GC_RD_ELM_1=("${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}" "d" "Wine Manager root directory")		# Root directory
declare -r GC_RD_ELM_2=("${GC_STR_ARY[$E_STR_WM_BTL_BCKP_DIR]}" "d" "Bottle backup directory")
declare -r GC_RD_ELM_3=("${GC_STR_ARY[$E_STR_WM_BIN_DIR]}" "d" "Bin directory")
declare -r GC_RD_ELM_4=("${GC_STR_ARY[$E_STR_WM_BTL_DIR]}" "d" "Bottle directory")
declare -r GC_RD_ELM_5=("${GC_STR_ARY[$E_STR_WM_RSRC_DIR]}" "d" "Resource directory")
declare -r GC_RD_ELM_6=("${GC_STR_ARY[$E_STR_WM_SRVC_DIR]}" "d" "Service directory")
declare -r GC_RD_ELM_7=("${GC_STR_ARY[$E_STR_WM_TMP_DIR]}" "d" "Temporary directory")
declare -r GC_RD_ELM_8=("${GC_STR_ARY[$E_STR_WM_BTL_TMPLT_DIR]}" "d" "Bottle template directory")
declare -r GC_RD_ELM_9=("${GC_STR_ARY[$E_STR_WM_CONF_FILE]}" "f" "Wine Manager configuration file")
declare -r GC_RD_ELM_10=("${GC_STR_ARY[$E_STR_WM_MON_SRVC_FILE]}" "f" "Bottle XDG monitor service")
declare -r GC_RD_ELM_11=("${GC_STR_ARY[$E_STR_WM_MON_BIN_FILE]}" "f" "Bottle XDG monitor shell script")
declare -r GC_RD_ELM_12=("${GC_STR_ARY[$E_STR_WM_XFCE_DSKTP_FILE]}" "f" "Dummy XFCE Desktop File resource")

# Array
# ~~~~~
declare -a GC_ROOT_DIR_ARY=(
   GC_RD_ELM_1[@]
   GC_RD_ELM_2[@]
   GC_RD_ELM_3[@]
   GC_RD_ELM_4[@]
   GC_RD_ELM_5[@]
   GC_RD_ELM_6[@]
   GC_RD_ELM_7[@]
   GC_RD_ELM_8[@]
   GC_RD_ELM_9[@]
   GC_RD_ELM_10[@]
   GC_RD_ELM_11[@]
   GC_RD_ELM_12[@]
)
readonly -a GC_ROOT_DIR_ARY

G_GLBL_VAR_ARY[$E_GLBL_ROOT_DIR_ARY_SIZE]=${#GC_ROOT_DIR_ARY[@]}

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Bottle Directory Constant Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Elements
# ~~~~~~~~
# Format: Dir/File Name, Dir/File type, Description
#
																# Bottle Bin directory
declare -r GC_BTL_ELM_1=("${GC_STR_ARY[$E_STR_BTL_BIN_DIR]}" "d" "Bottle bin directory")
																# Bottle Wine version
declare -r GC_BTL_ELM_2=("${GC_STR_ARY[$E_STR_BTL_WINE_VER]}" "d" "Bottle wine version")
																# Bottle XDG directory
declare -r GC_BTL_ELM_3=("${GC_STR_ARY[$E_STR_BTL_XDG_DIR]}" "d" "Bottle XDG directory")
																# Bottle Configuration file
declare -r GC_BTL_ELM_4=("${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}" "f" "Bottle configuration file")
																# Private Bottle XDG
declare -r GC_BTL_ELM_5=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}/Desktop" "d" "Private Bottle XDG 'Desktop' directory")
declare -r GC_BTL_ELM_6=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}/.config/menus/applications-merged" "d" "Private Bottle XDG '.config/menus/applications-merged' directory")
declare -r GC_BTL_ELM_7=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}/.local/share/applications/wine/Programs" "d" "Private Bottle XDG '.local/share/applications/wine/Programs' directory")
declare -r GC_BTL_ELM_8=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}/.local/share/desktop-directories" "d" "Private Bottle XDG '.local/share/desktop-directories' directory")
declare -r GC_BTL_ELM_9=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}/.local/share/icons" "d" "Private Bottle XDG '.local/share/icons' directory")
declare -r GC_BTL_ELM_10=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}/.local/share/mime" "d" "Private Bottle XDG '.local/share/mime' directory")
																# Bottle Multiplexer XDG
declare -r GC_BTL_ELM_11=("${GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]}/Desktop" "d" "Bottle XDG Multiplexer 'Desktop' directory")
declare -r GC_BTL_ELM_12=("${GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]}/.config/menus" "d" "Bottle XDG Multiplexer '.config/menus' directory")
declare -r GC_BTL_ELM_13=("${GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]}/.local/share/applications" "d" "Bottle XDG Multiplexer '.local/share/applications' directory")
declare -r GC_BTL_ELM_14=("${GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]}/.local/share/desktop-directories" "d" "Bottle XDG Multiplexer '.local/share/desktop-directories' directory")
declare -r GC_BTL_ELM_15=("${GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]}/.local/share/icons" "d" "Bottle XDG Multiplexer '.local/share/icons' directory")
declare -r GC_BTL_ELM_16=("${GC_XDG_DIR_ARY[$E_XDG_BOTTLE_MUX]}/.local/share/mime" "d" "Bottle XDG Multiplexer '.local/share/mime' directory")
																# Private Bottle Translate XDG
declare -r GC_BTL_ELM_17=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE_TRANS]}/Desktop" "d" "Private Bottle Translate XDG 'Desktop' directory")
declare -r GC_BTL_ELM_18=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE_TRANS]}/.config/menus" "d" "Private Bottle Translate XDG '.config/menus' directory")
declare -r GC_BTL_ELM_19=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE_TRANS]}/.local/share/applications" "d" "Private Bottle Translate XDG '.local/share/applications' directory")
declare -r GC_BTL_ELM_20=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE_TRANS]}/.local/share/desktop-directories" "d" "Private Bottle Translate XDG '.local/share/desktop-directories' directory")
declare -r GC_BTL_ELM_21=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE_TRANS]}/.local/share/icons" "d" "Private Bottle Translate XDG '.local/share/icons' directory")
declare -r GC_BTL_ELM_22=("${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE_TRANS]}/.local/share/mime" "d" "Private Bottle Translate XDG '.local/share/mime' directory")


# Array
# ~~~~~
declare -a GC_BTL_DIR_ARY=(
   GC_BTL_ELM_1[@]
   GC_BTL_ELM_2[@]
   GC_BTL_ELM_3[@]
   GC_BTL_ELM_4[@]
   GC_BTL_ELM_5[@]
   GC_BTL_ELM_6[@]
   GC_BTL_ELM_7[@]
   GC_BTL_ELM_8[@]
   GC_BTL_ELM_9[@]
   GC_BTL_ELM_10[@]
   GC_BTL_ELM_11[@]
   GC_BTL_ELM_12[@]
   GC_BTL_ELM_13[@]
   GC_BTL_ELM_14[@]
   GC_BTL_ELM_15[@]
   GC_BTL_ELM_16[@]
   GC_BTL_ELM_17[@]
   GC_BTL_ELM_18[@]
   GC_BTL_ELM_19[@]
   GC_BTL_ELM_20[@]
   GC_BTL_ELM_21[@]
   GC_BTL_ELM_22[@]
)
readonly -a GC_BTL_DIR_ARY
G_GLBL_VAR_ARY[$E_GLBL_BTL_DIR_ARY_SIZE]=${#GC_BTL_DIR_ARY[@]}


# ~~~~~~~~~~~~~~~~~~~~~
# Syntax Constant Array
# ~~~~~~~~~~~~~~~~~~~~~

declare -a GC_SYNTAX_ARY						# Constant Array

GC_SYNTAX_ARY[$E_SYTX_APPEND]="${GC_STR_ARY[$E_STR_CMD_APPEND]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name> ${GC_STR_ARY[$E_STR_TOKSTR_VAL]} <value> [${GC_STR_ARY[$E_STR_TOKSTR_SUB_DIR]} <subdirectory>]"
GC_SYNTAX_ARY[$E_SYTX_BACKUP]="${GC_STR_ARY[$E_STR_CMD_BACKUP]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name>"
GC_SYNTAX_ARY[$E_SYTX_CHANGE]="${GC_STR_ARY[$E_STR_CMD_CHANGE]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name> [${GC_STR_ARY[$E_STR_TOKSTR_NAME]} <name>] [${GC_STR_ARY[$E_STR_TOKSTR_WINE_VER]} <wine dir | \"\">] [${GC_STR_ARY[$E_STR_TOKSTR_ENV]} <env file | \"\">] [${GC_STR_ARY[$E_STR_TOKSTR_SUBMENU]} <submenu | \"\">]"
GC_SYNTAX_ARY[$E_SYTX_CONF]="${GC_STR_ARY[$E_STR_CMD_CONF]} ${GC_STR_ARY[$E_STR_TOKSTR_OPT]} <bottle | manager> ${GC_STR_ARY[$E_STR_TOKSTR_NAME]} <variable name> ${GC_STR_ARY[$E_STR_TOKSTR_VAL]} <value> [${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name | \"\">]"
GC_SYNTAX_ARY[$E_SYTX_CONSOLE]="${GC_STR_ARY[$E_STR_CMD_CONSOLE]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name>"
GC_SYNTAX_ARY[$E_SYTX_CREATE]="${GC_STR_ARY[$E_STR_CMD_CREATE]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name> [${GC_STR_ARY[$E_STR_TOKSTR_WINE_VER]} <wine dir>] [${GC_STR_ARY[$E_STR_TOKSTR_ENV]} <env file>] [${GC_STR_ARY[$E_STR_TOKSTR_SUBMENU]} <submenu>]"
GC_SYNTAX_ARY[$E_SYTX_DEFAULT]="${GC_STR_ARY[$E_STR_CMD_DEFAULT]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name | \"\">"
GC_SYNTAX_ARY[$E_SYTX_DEINIT]="${GC_STR_ARY[$E_STR_CMD_DEINIT]}"
GC_SYNTAX_ARY[$E_SYTX_DELETE]="${GC_STR_ARY[$E_STR_CMD_DELETE]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name> ${GC_STR_ARY[$E_STR_TOKSTR_OPT]} <bottle | backup>"
GC_SYNTAX_ARY[$E_SYTX_EDIT]="${GC_STR_ARY[$E_STR_CMD_EDIT]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name> ${GC_STR_ARY[$E_STR_TOKSTR_OLD_VAL]} <old value> ${GC_STR_ARY[$E_STR_TOKSTR_VAL]} <new value> [${GC_STR_ARY[$E_STR_TOKSTR_SUB_DIR]} <subdirectory>]"
GC_SYNTAX_ARY[$E_SYTX_HELP]="${GC_STR_ARY[$E_STR_CMD_HELP]} [${GC_STR_ARY[$E_STR_TOKSTR_OPT]} <command>]"
GC_SYNTAX_ARY[$E_SYTX_INIT]="${GC_STR_ARY[$E_STR_CMD_INIT]}"
GC_SYNTAX_ARY[$E_SYTX_INSTANTIATE]="${GC_STR_ARY[$E_STR_CMD_INSTANTIATE]} [ ${GC_STR_ARY[$E_STR_TOKSTR_FORCE]} ]"
GC_SYNTAX_ARY[$E_SYTX_LIST]="${GC_STR_ARY[$E_STR_CMD_LIST]} ${GC_STR_ARY[$E_STR_TOKSTR_OPT]} <bottle | backup>"
GC_SYNTAX_ARY[$E_SYTX_MIGRATE]="${GC_STR_ARY[$E_STR_CMD_MIGRATE]} ${GC_STR_ARY[$E_STR_TOKSTR_OPT]} <copy | move | todir | tolnk> [ ${GC_STR_ARY[$E_STR_TOKSTR_VAL]} <destination directory> ]"
GC_SYNTAX_ARY[$E_SYTX_REFRESH]="${GC_STR_ARY[$E_STR_CMD_REFRESH]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name | \"\">"
GC_SYNTAX_ARY[$E_SYTX_RESTORE]="${GC_STR_ARY[$E_STR_CMD_RESTORE]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name>"
GC_SYNTAX_ARY[$E_SYTX_VERSION]="${GC_STR_ARY[$E_STR_CMD_VERSION]}"
GC_SYNTAX_ARY[$E_SYTX_XDG]="${GC_STR_ARY[$E_STR_CMD_XDG]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} <bottle name | \"\"> ${GC_STR_ARY[$E_STR_TOKSTR_OPT]} <on | off>"

readonly -a GC_SYNTAX_ARY

# ~~~~~~~~~~~~~~~~~~~~
# Usage Constant Array
# ~~~~~~~~~~~~~~~~~~~~

declare -a GC_USAGE_ARY							# Constant Array

GC_USAGE_ARY[$E_USG_APPEND]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_APPEND]}"
GC_USAGE_ARY[$E_USG_BACKUP]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_BACKUP]}"
GC_USAGE_ARY[$E_USG_CHANGE]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_CHANGE]}"
GC_USAGE_ARY[$E_USG_CONF]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_CONF]}"
GC_USAGE_ARY[$E_USG_CONSOLE]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_CONSOLE]}"
GC_USAGE_ARY[$E_USG_CREATE]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_CREATE]}"
GC_USAGE_ARY[$E_USG_DEFAULT]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_DEFAULT]}"
GC_USAGE_ARY[$E_USG_DEINIT]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_DEINIT]}"
GC_USAGE_ARY[$E_USG_DELETE]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_DELETE]}"
GC_USAGE_ARY[$E_USG_EDIT]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_EDIT]}"
GC_USAGE_ARY[$E_USG_HELP]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_HELP]}"
GC_USAGE_ARY[$E_USG_INIT]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_INIT]}"
GC_USAGE_ARY[$E_USG_INSTANTIATE]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_INSTANTIATE]}"
GC_USAGE_ARY[$E_USG_LIST]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_LIST]}"
GC_USAGE_ARY[$E_USG_MIGRATE]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_MIGRATE]}"
GC_USAGE_ARY[$E_USG_REFRESH]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_REFRESH]}"
GC_USAGE_ARY[$E_USG_RESTORE]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_RESTORE]}"
GC_USAGE_ARY[$E_USG_VERSION]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_VERSION]}"
GC_USAGE_ARY[$E_USG_XDG]="$ThisNameUser ${GC_SYNTAX_ARY[E_SYTX_XDG]}"

readonly -a GC_USAGE_ARY

# ~~~~~~~~~~~~~~~~~~~
# Help Constant Array
# ~~~~~~~~~~~~~~~~~~~

declare -a GC_HELP_ARY						# Constant Array

GC_HELP_ARY[$E_HLP_APPEND]="${GC_SYNTAX_ARY[$E_SYTX_APPEND]}\n\
\tAppends \"value\" to the end of every bottle .desktop file \"Exec=\" line.\n\
\tIf \"subdirectory\" is specified only files in that directory will be\n\
\tchanged"

GC_HELP_ARY[$E_HLP_BACKUP]="${GC_SYNTAX_ARY[$E_SYTX_BACKUP]}\n\
\tBackup bottle to Wine Manager backup directory. It can be restored later\n\
\twith \"restore\" command"

GC_HELP_ARY[$E_HLP_CHANGE]="${GC_SYNTAX_ARY[$E_SYTX_CHANGE]}\n\
\tChanges bottle name, wine version, environment file, or submenu to\n\
\t\"new value\". A null \"new value\" string can be passed for everything\n\
\texcept \"name\" to set the wine version to default, or delete the\n\
\tenvironment file or submenu"

GC_HELP_ARY[$E_HLP_CONF]="${GC_SYNTAX_ARY[$E_SYTX_CONF]}\n\
\tSet configuration \"variable name\" to \"value\". The bottle name option is\n\
\trequired if setting a bottle variable, if it\x27s a null string the variable\n\
\tis written to all bottles."

GC_HELP_ARY[$E_HLP_CONSOLE]="${GC_SYNTAX_ARY[$E_SYTX_CONSOLE]}\n\
\tInvokes a subshell console for bottle named \"bottle name\" with all a\n\
\tenvironment variables set for the bottle and its wine directory.\n\
\tAll programs installed from the command line must be done in a\n\
\tconsole subshell or the environment may be incorrect and its XDG\n\
\tchanges will be lost"

GC_HELP_ARY[$E_HLP_CREATE]="${GC_SYNTAX_ARY[$E_SYTX_CREATE]}\n\
\tCreate Wine bottle named \"bottle name\". If \"dir\" is specified then\n\
\tthat wine version will be used with bottle, otherwise the system default\n\
\tdirectory is used. If \"env file\" is specified it is copied and sourced\n\
\tbefore executing commands. If \"submenu\" is specified then the bottle\n\
\twill have its own submenu. Multi-level submenus can be created by\n\
\tseperating levels with \":\""

GC_HELP_ARY[$E_HLP_DEFAULT]="${GC_SYNTAX_ARY[$E_SYTX_DEFAULT]}\n\
\tSet bottle \"bottle name\" as default bottle for wine commands that\n\
\tdon\x27t specify a directory/bottle. This links bottle to ~/.wine and\n\
\tif the bottle has a Wine version it\x27s linked to WINEMGR_DFLT_DIR.\n\
\tIf no Wine version then WINEMGR_DFLT_DIR is deleted and the system\n\
\tWine will be used. If a null bottle name is specified then all\n\
\tdefault links are deleted"

GC_HELP_ARY[$E_HLP_DEINIT]="${GC_SYNTAX_ARY[$E_SYTX_DEINIT]}\n\
\tDeinitialize Wine Manager system"

GC_HELP_ARY[$E_HLP_DELETE]="${GC_SYNTAX_ARY[$E_SYTX_DELETE]}\n\
\tDeletes Wine bottle or backup named \"bottle name\""

GC_HELP_ARY[$E_HLP_EDIT]="${GC_SYNTAX_ARY[$E_SYTX_EDIT]}\n\
\tGenerically edits all bottle .desktop files changing \"old value\" to\n\
\t\"new value\". If \"subdirectory\" is specified only files in that\n\
\tdirectory will be changed"

GC_HELP_ARY[$E_HLP_HELP]="${GC_SYNTAX_ARY[$E_SYTX_HELP]}\n\
\tDisplay usage help"


GC_HELP_ARY[$E_HLP_INIT]="${GC_SYNTAX_ARY[$E_SYTX_INIT]}\n\
\tInitialize Wine Manager system"

GC_HELP_ARY[$E_HLP_INSTANTIATE]="${GC_SYNTAX_ARY[$E_SYTX_INSTANTIATE]}\n\
\tInstantiate Wine Manager directory"

GC_HELP_ARY[$E_HLP_LIST]="${GC_SYNTAX_ARY[$E_SYTX_LIST]}\n\
\tLists all bottles or backup bottles"

GC_HELP_ARY[$E_HLP_MIGRATE]="${GC_SYNTAX_ARY[$E_SYTX_MIGRATE]}\n\
\tMigrates the Wine Manager data directory. \"copy\" or \"move\" to a specified\n\
\tdirectory, \"todir\" converts a linked data directory to an absolute directory,\n\
\tand \"tolnk\" converts an absolute path to a link. For \"copy\", \"move\", and\n\
\t\"tolnk\" a destination directory/target link must be specified. After\n\
\tmigration it\x27s critical to remember to change the Wine Manager environment\n\
\tvariables before attempting to use Wine Manager with the new location"

GC_HELP_ARY[$E_HLP_REFRESH]="${GC_SYNTAX_ARY[$E_SYTX_REFRESH]}\n\
\tRefreshes Translate XDG for bottle \"bottle name\", or all bottles if null\n\
\tstring"

GC_HELP_ARY[$E_HLP_RESTORE]="${GC_SYNTAX_ARY[$E_SYTX_RESTORE]}\n\
\tRestore saved bottle to main Wine Manager bottle directory"

GC_HELP_ARY[$E_HLP_VERSION]="${GC_SYNTAX_ARY[$E_SYTX_VERSION]}\n\
\tDisplay Wine Manager version"

GC_HELP_ARY[$E_HLP_XDG]="${GC_SYNTAX_ARY[$E_SYTX_XDG]}\n\
\tTurn Host XDG on or off for bottle \"bottle name\", or all bottles if null\n\
\tstring"

GC_HELP_ARY[$E_HLP_ALL]="\
${GC_HELP_ARY[$E_HLP_APPEND]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_BACKUP]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_CHANGE]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_CONF]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_CONSOLE]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_CREATE]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_DEFAULT]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_DEINIT]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_DELETE]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_EDIT]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_HELP]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_INIT]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_INSTANTIATE]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_LIST]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_MIGRATE]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_REFRESH]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_RESTORE]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_VERSION]}\
.\n\n\
${GC_HELP_ARY[$E_HLP_XDG]}"

readonly -a GC_HELP_ARY

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Token Parser Variable Array
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
declare -a G_TOK_VAR_ARY						# Variable Array

G_TOK_VAR_ARY[$E_TOK_NUM_TOKS]=0
G_TOK_VAR_ARY[$E_TOK_LAST_II]=0
G_TOK_VAR_ARY[$E_TOK_LAST_PI]=0
G_TOK_VAR_ARY[$E_TOK_LAST_AI]=0
		
G_TOK_VAR_ARY[$E_TOK_CMD]=""					# Command argument
G_TOK_VAR_ARY[$E_TOK_ENV]=""					# Environment file argument
G_TOK_VAR_ARY[$E_TOK_BTL]=""					# Bottle name argument
G_TOK_VAR_ARY[$E_TOK_MODE]=""					# Mode argument
G_TOK_VAR_ARY[$E_TOK_OPT]=""					# Option argument
G_TOK_VAR_ARY[$E_TOK_SUBMENU]=""				# Submenu argument
G_TOK_VAR_ARY[$E_TOK_SUB_DIR]=""				# Subdirectory argument
G_TOK_VAR_ARY[$E_TOK_WINE_VER]=""			# Wine version argument
G_TOK_VAR_ARY[$E_TOK_NAME]=""					# New name argument
G_TOK_VAR_ARY[$E_TOK_OLD_VAL]=""				# Old value argument
G_TOK_VAR_ARY[$E_TOK_VAL]=""					# New value argument

G_TOK_VAR_ARY[$E_TOK_CMDF]=0					# Command token found
G_TOK_VAR_ARY[$E_TOK_ENVF]=0					# Environment file token found
G_TOK_VAR_ARY[$E_TOK_BTLF]=0					# Bottle name token found
G_TOK_VAR_ARY[$E_TOK_MODEF]=0					# Mode token found
G_TOK_VAR_ARY[$E_TOK_OPTF]=0					# Option token found
G_TOK_VAR_ARY[$E_TOK_SUBMENUF]=0				# Submenu token found
G_TOK_VAR_ARY[$E_TOK_SUB_DIRF]=0				# Subdirectory token found
G_TOK_VAR_ARY[$E_TOK_WINE_VERF]=0			# Wine version token found
G_TOK_VAR_ARY[$E_TOK_NAMEF]=0					# New name token found
G_TOK_VAR_ARY[$E_TOK_OLD_VALF]=0				# Old value token found
G_TOK_VAR_ARY[$E_TOK_VALF]=0					# New value token found
G_TOK_VAR_ARY[$E_TOK_MINVFYF]=0				# Minimum verify token found
G_TOK_VAR_ARY[$E_TOK_FORCEF]=0				# Force token found

# ~~~~~~~~~~~~~~~~~~
# Token Parser Array
# ~~~~~~~~~~~~~~~~~~
#
# Elements
# ~~~~~~~~
# Token, Token Found Var Name, Min Args, Max Args, Arg Var Name, ...
G_TOK_ELM_0=("${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" "G_TOK_VAR_ARY[$E_TOK_CMDF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_CMD]")
G_TOK_ELM_1=("${GC_STR_ARY[$E_STR_TOKSTR_ENV]}" "G_TOK_VAR_ARY[$E_TOK_ENVF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_ENV]")
G_TOK_ELM_2=("${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "G_TOK_VAR_ARY[$E_TOK_BTLF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_BTL]")
G_TOK_ELM_3=("${GC_STR_ARY[$E_STR_TOKSTR_MODE]}" "G_TOK_VAR_ARY[$E_TOK_MODEF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_MODE]")
G_TOK_ELM_4=("${GC_STR_ARY[$E_STR_TOKSTR_OPT]}" "G_TOK_VAR_ARY[$E_TOK_OPTF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_OPT]")
G_TOK_ELM_5=("${GC_STR_ARY[$E_STR_TOKSTR_SUBMENU]}" "G_TOK_VAR_ARY[$E_TOK_SUBMENUF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_SUBMENU]")
G_TOK_ELM_6=("${GC_STR_ARY[$E_STR_TOKSTR_SUB_DIR]}" "G_TOK_VAR_ARY[$E_TOK_SUB_DIRF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_SUB_DIR]")
G_TOK_ELM_7=("${GC_STR_ARY[$E_STR_TOKSTR_WINE_VER]}" "G_TOK_VAR_ARY[$E_TOK_WINE_VERF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_WINE_VER]")
G_TOK_ELM_8=("${GC_STR_ARY[$E_STR_TOKSTR_NAME]}" "G_TOK_VAR_ARY[$E_TOK_NAMEF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_NAME]")
G_TOK_ELM_9=("${GC_STR_ARY[$E_STR_TOKSTR_OLD_VAL]}" "G_TOK_VAR_ARY[$E_TOK_OLD_VALF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_OLD_VAL]")
G_TOK_ELM_10=("${GC_STR_ARY[$E_STR_TOKSTR_VAL]}" "G_TOK_VAR_ARY[$E_TOK_VALF]" "1" "1" "G_TOK_VAR_ARY[$E_TOK_VAL]")
G_TOK_ELM_11=("${GC_STR_ARY[$E_STR_TOKSTR_MINVFY]}" "G_TOK_VAR_ARY[$E_TOK_MINVFYF]" "0" "0")
G_TOK_ELM_12=("${GC_STR_ARY[$E_STR_TOKSTR_FORCE]}" "G_TOK_VAR_ARY[$E_TOK_FORCEF]" "0" "0")

# Array
# ~~~~~
G_TOK_ARY=(
   G_TOK_ELM_0[@]
   G_TOK_ELM_1[@]
   G_TOK_ELM_2[@]
   G_TOK_ELM_3[@]
   G_TOK_ELM_4[@]
   G_TOK_ELM_5[@]
   G_TOK_ELM_6[@]
   G_TOK_ELM_7[@]
   G_TOK_ELM_8[@]
   G_TOK_ELM_9[@]
   G_TOK_ELM_10[@]
   G_TOK_ELM_11[@]
   G_TOK_ELM_12[@]
)
G_GLBL_VAR_ARY[$E_GLBL_TOK_ARY_SIZE]=${#G_TOK_ARY[@]}

declare -a G_INPUT_ARY									# Command input string array
