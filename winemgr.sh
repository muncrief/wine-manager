#!/bin/bash
#set -x
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                             Wine Manager Version 2                          *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
# Function:	Manages multiple Wine versions and bottles so they can be used
#				simultaneously. Also creates an integrated customizable XDG menu
#				that can be used to hide or reveal various bottle menus.
#
# 
#				Global Environment Variables
#				----------------------------
# Wine Manager Variables:
# export WINEMGR_ROOT="`echo ~/.winemgr`"
# export WINEMGR_XDG_HOST="`echo ~/.winemgr_xdg_host`"
# export WINEMGR_XDG_HOST_MUX="`echo ~/`"
# export WINEMGR_XDG_REFRESH="winemgr_xdg_refresh.sh"
#
# Default Wine Paths:
# export WINEMGR_DWINE_PATH=`echo $WINEMGR_ROOT/wine_dflt`
# export PATH=$WINEMGR_DWINE_PATH/bin:$PATH 
# export WINESERVER=$WINEMGR_DWINE_PATH/bin/wineserver
# export WINELOADER=$WINEMGR_DWINE_PATH/bin/wine
# export WINEDLLPATH=$WINEMGR_DWINE_PATH/lib/wine/fakedlls:$WINEMGR_DWINE_PATH/lib32/wine/fakedlls
# export LD_LIBRARY_PATH="$WINEMGR_DWINE_PATH/lib:$WINEMGR_DWINE_PATH/lib32:$LD_LIBRARY_PATH" 
# 
# Usage: <script name> followed by:
#
#	append -b <bottle name> -nv <value> [-subdir <subdirectory>]
#		Appends "value" to the end of every bottle .desktop file "Exec=" line.
#		If "subdirectory" is specified only files in that directory will be
#		changed.
#
#	backup -b <bottle name>
#		Backup bottle to Wine Manager backup directory. It can be restored later
#		with "restore" command.
#
#	change -b <bottle name> [-name <name>] [-ver <wine dir | "">] [-env <env file | "">] [-submenu <submenu | "">]
#		Changes bottle name, wine version, environment file, or submenu to
#		"new value". A null "new value" string can be passed for everything
#		except "name" to set the wine version to default, or delete the
#		environment file or submenu.
#
#	conf -op <bottle | manager> -name <variable name> -nv <value> [-b <bottle name | "">]
#		Set configuration "variable name" to "value". The bottle name option is
#		required if setting a bottle variable, if it's a null string the variable
#		is written to all bottles.
#
#	console -b <bottle name>
#		Invokes a subshell console for bottle named "bottle name" with all a
#		environment variables set for the bottle and its wine directory.
#		All programs installed from the command line must be done in a
#		console subshell or the environment may be incorrect and its XDG
#		changes will be lost.
#
#	create -b <bottle name> [-dir <wine dir>] [-env <env file>] [-submenu <submenu>]
#		Create Wine bottle named "bottle name". If "dir" is specified then
#		that wine version will be used with bottle, otherwise the system default
#		directory is used. If "env file" is specified it is copied and sourced
#		before executing commands. If "submenu" is specified then the bottle
#		will have its own submenu. Multi-level submenus can be created by
#		seperating levels with ":".
#
#	default -b <bottle name | "">
#		Set bottle "bottle name" as default bottle for wine commands that
#		don't specify a directory/bottle. This links bottle to ~/.wine and
#		if the bottle has a Wine version it's linked to WINEMGR_DFLT_DIR.
#		If no Wine version then WINEMGR_DFLT_DIR is deleted and the system
#		Wine will be used. If a null bottle name is specified then all
#		default links are deleted.
#
#	delete -b <bottle name> -op <bottle | backup>
#		Deletes Wine bottle or backup named "bottle name".
#
#	edit -b <bottle name> -ov <old value> -nv <new value> [-subdir <subdirectory>]
#		Generically edits all bottle .desktop files changing "old value" to
#		"new value". If "subdirectory" is specified only files in that
#		directory will be changed.
#
#	help
#		Display usage help
#
#	init
#		Initialize Wine Manager directory
#
#	list -op <bottle | backup>
#		Lists all bottles or backup bottles.
#
#	migrate -op <copy | move | todir | tolnk> [ -nv <destination directory/link> ]
#		Migrates the Wine Manager data directory. "copy" or "move" to a specified
#		directory, "todir" converts a linked data directory to an absolute directory,
#		and "tolnk" converts an absolute path to a link. For "copy", "move", and
#		"tolnk" a destination directory/target link must be specified. After
#		migration it's critical to remember to change the Wine Manager environment
#		variables before attempting to use Wine Manager with the new location.
#
#	restore -b <bottle name>
#		Restore saved bottle to main Wine Manager bottle directory.
#
#	version
#		Display Wine Manager version
#
#	xdg -b <bottle name | ""> -op <on | off>
#		Enable or disable Host XDG for bottle "bottle name", or all bottles if
#		null string.
#
#
# Exit Status: 0		 		# Command success
#				 	1				# Error
#
#*******************************************************************************
#*                                                                             *
#*											Global Variables										 *
#*                                                                             *
#*******************************************************************************
set -u										# Set safe scripting options

. /usr/local/bin/standard_vars.sh	# Standard variables
. /usr/local/bin/key_file_vars.sh	# Key File variables
. /usr/local/bin/winemgr_vars.sh		# Global Wine Manager variables

# ------------------
# Standard Variables
# ------------------

Dbg=0											# 1 to enable debug output
DbgLog=0										# 1 to enable debug logging
LogCmd="logger_home"						# System log command
ThisAppName="Wine Manager"				# Application name
ThisVersion="2.0"							# Application version

#*******************************************************************************
#*                                                                             *
#*											Functions											 	 *
#*                                                                             *
#*******************************************************************************

. /usr/local/bin/standard_functions.sh				# Standard functions
. /usr/local/bin/key_file.sh							# Key File functions
. /usr/local/bin/token_parser.sh						# Token parser


#*******************************************************************************
#*								  	Wine Manager Instantiate									 *
#*******************************************************************************
#
# Function: Instantiates new Wine Manager root directory.
#
# Input:
#	Arg1  Force instantiation flag. 0 = Don't force, 1 = Force.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg4  Root Directory Array name.
#	Arg5	Bottle Directory Array name.
#	Arg6	XDG Directory Array name.
#	Arg7	XDG Subpath Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function WineManagerInstantiate()
{
	local l_ForceFlag="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_RootDirAry="$4"
	local -n l_BtlDirAry="$5"
	local -n l_XdgDirAry="$6"
	local -n l_XdgSubpathAry="$7"
	local l_RetStat=$WM_ERR_NONE
	local l_Answer=""
	local l_BottleName=""
	local l_ConfFile=""
	local l_Name=""
	local l_Type=""
	local l_Desc=""
	local l_TmpStr=""
	local -a l_BtlAry

	DbgPrint "${FUNCNAME[0]}: Entered with Force flag = \"$l_ForceFlag\",  root directory =  \"${l_GlblVarAry[$E_GLBL_ROOT]}\""
																# If data directory already exists
	if [ -e "${l_GlblVarAry[$E_GLBL_ROOT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Previous root directory detected \"${l_GlblVarAry[$E_GLBL_ROOT]}\""
		if [ $l_ForceFlag -ne 1 ]; then				# Error if force instantiation not enabled
			DbgPrint "${FUNCNAME[0]}: Force instantiate not detected, exiting with error"
			ErrAdd $WM_ERR_DIR_EXISTS "${FUNCNAME[0]}${GC_SEP_FTRC}Root directory = \"${l_GlblVarAry[$E_GLBL_ROOT]}\"" "${!l_GlblVarAry}"
			MsgAdd $GC_MSGT_INFO "If you wish to delete the directory use the \"${GC_STR_ARY[$E_STR_TOKSTR_FORCE]}\" option" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
																# Otherwise deinit just in case
		DbgPrint "${FUNCNAME[0]}: Force command detected, deinitializing Wine Manager, ignoring errors"
		WineManagerDeinit "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}"
		MsgClear ${!l_GlblVarAry}						# We don't care about errors
																# Delete remaining contents
		DbgPrint "${FUNCNAME[0]}: Deleting all remaining data in '${l_GlblVarAry[$E_GLBL_ROOT]}'"
		find "${l_GlblVarAry[$E_GLBL_ROOT]}/." -name . -o -prune -exec rm -rf -- {} +
		DbgPrint "${FUNCNAME[0]}: All data in '${l_GlblVarAry[$E_GLBL_ROOT]}' deleted as requested."
																# Add info message
		MsgAdd $GC_MSGT_INFO "All data in '${l_GlblVarAry[$E_GLBL_ROOT]}' deleted as requested" "${!l_GlblVarAry}"
	fi

# Create Root Directory
# ---------------------
	DbgPrint "${FUNCNAME[0]}: Instantiating Wine manager root directory '${l_GlblVarAry[$E_GLBL_ROOT]}'."
																# Add info message
	MsgAdd $GC_MSGT_INFO  "Instantiating Wine Manager root directory \"${l_GlblVarAry[$E_GLBL_ROOT]}\"" "${!l_GlblVarAry}"
	for ((i=0; i < ${l_GlblVarAry[$E_GLBL_ROOT_DIR_ARY_SIZE]}; i++)); do
		l_Name="${!l_RootDirAry[i]:0:1}"
		l_Type="${!l_RootDirAry[i]:1:1}"
		l_Desc="${!l_RootDirAry[i]:2:1}"

		case "$l_Type" in
			d)													# Directory
				DbgPrint "${FUNCNAME[0]}: Creating directory '$l_Name'."
				mkdir -p "$l_Name"  >/dev/null 2>&1						# Create directory
				if [ ! -d "$l_Name" ]; then			# If create failed
					ErrAdd $WM_ERR_DIR_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;

			f)													# File
				DbgPrint "${FUNCNAME[0]}: Creating file '$l_Name'."
				touch "$l_Name"  >/dev/null 2>&1							# Create file
				if [ ! -f "$l_Name" ]; then			# If create failed
					ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;
		
			*)													# Unknown
				ErrAdd $WM_ERR_UNK_FD_TYPE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Type = \"$l_Type\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			;;
		esac
	done

# Add Wine Manager Configuration Keys
# -----------------------------------
	l_ConfFile="${l_StrAry[$E_STR_WM_CONF_FILE]}"
																# Wine Manager ID key
	KeyAdd "${l_StrAry[$E_STR_KEY_WM_ID]}" "" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_WM_ID]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Initialized key
	KeyAdd "${l_StrAry[$E_STR_KEY_WM_INIT]}" "0" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_WM_INIT]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Default wine dir key
	KeyAdd "${l_StrAry[$E_STR_KEY_BTL_DFLT]}" "" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	

# Create Bottle Template
# ----------------------
	for ((i=0; i < ${l_GlblVarAry[$E_GLBL_BTL_DIR_ARY_SIZE]}; i++)); do
		l_Name="${!l_BtlDirAry[i]:0:1}"
		l_Type="${!l_BtlDirAry[i]:1:1}"
		l_Desc="${!l_BtlDirAry[i]:2:1}"

		case "$l_Type" in
			d)													# Directory
				DbgPrint "${FUNCNAME[0]}: Creating directory '${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name'."
																# Create directory
				mkdir -p "${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name" >/dev/null 2>&1
																# If create failed
				if [ ! -d "${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name" ]; then
					ErrAdd $WM_ERR_DIR_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;
			
			f)													# File
				DbgPrint "${FUNCNAME[0]}: Creating file '${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name'."
																# Create file
				touch "${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name" >/dev/null 2>&1
																# If create failed
				if [ ! -f "${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name" ]; then
					ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;

			*)													# Unknown
				ErrAdd $WM_ERR_UNK_FD_TYPE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/$l_Name\", Type = \"$l_Type\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			;;
		esac
	done

# Add Bottle Template Configuration Keys
# --------------------------------------
	l_ConfFile="${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
																# Bottle wine version key
	KeyAdd "${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}" "" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Bottle environment script key
	KeyAdd "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Bottle submenu key
	KeyAdd "${l_StrAry[$E_STR_KEY_BTL_SMENU]}" "" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_SMENU]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Bottle XDG enable key
	KeyAdd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "$GC_BTL_XDG_DSB" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	

# Create SystemD Monitor Service
# ------------------------------

	XdgMonCreateService "${!l_GlblVarAry}" "${!l_StrAry}"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

# Install Wine Manager XDG Change Monitor SystemD Service
# -------------------------------------------------------
	XdgMonInstall "${!l_GlblVarAry}" "${!l_StrAry}"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

#
# Create System Bottle
# --------------------
	l_BottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
	BottleCreate "$l_BottleName" "" "" "" "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}"
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
																# Bottle conf file
	l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
																# Create wine-wine.directory file
	l_TmpStr="${l_BottlePathname}/xdg/pri_bottle/.local/share/desktop-directories/wine-wine.directory"
	cat > "$l_TmpStr" <<EOL
[Desktop Entry]
Type=Directory
Name=Wine
Icon=wine
EOL
	if [ ! -f "$l_TmpStr" ]; then						# If create failed
		ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

																# Create wine-Programs.directory file
	l_TmpStr="${l_BottlePathname}/xdg/pri_bottle/.local/share/desktop-directories/wine-Programs.directory"
	cat > "$l_TmpStr" <<EOL
[Desktop Entry]
Type=Directory
Name=Programs
Icon=folder
EOL
	if [ ! -f "$l_TmpStr" ]; then						# If create failed
		ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

																# Create Wine Manager .directory file
	l_TmpStr="${l_BottlePathname}/xdg/pri_bottle/.local/share/desktop-directories/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}.directory"
	cat > "$l_TmpStr" <<EOL
[Desktop Entry]
Type=Directory
Name=${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}
Icon=folder
EOL
	if [ ! -f "$l_TmpStr" ]; then						# If create failed
		ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi
																# Create Wine Manager Programs directory
	l_TmpStr="${l_BottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}"
	mkdir "$l_TmpStr" >/dev/null 2>&1

	if [ ! -d "$l_TmpStr" ]; then						# If create failed
		ErrAdd $WM_ERR_DIR_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi
																# Set bottle XDG enable key
	KeyWr "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "$GC_BTL_XDG_ENB" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*									  	Wine Manager Initialize									 *
#*******************************************************************************
#
# Function: Initialize Wine Manager system.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2	Strings Array name.
#	Arg3	XDG Directory Array name.
#	Arg4	XDG Subpath Array name.
#	Arg5	XDG Desktop File Subpath Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function WineManagerInit ()
{
	local -n l_GlblVarAry="$1"
	local -n l_StrAry="$2"
	local -n l_XdgDirAry="$3"
	local -n l_XdgSubpathAry="$4"
	local -n l_XdgDsktpSubpathAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleName=""
	local l_WineDirName=""
	local -a l_Ary

	DbgPrint "${FUNCNAME[0]}: Entered"
																# Deinit just in case
	WineManagerDeinit "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}"
	MsgClear "${!l_GlblVarAry}"						# We don't care about errors

	DbgPrint "${FUNCNAME[0]}: Creating SystemD XDG Monitor if it doesn't exist"
	XdgMonInstall "${!l_GlblVarAry}" "${!l_StrAry}"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

	DbgPrint "${FUNCNAME[0]}: Mounting all bottles in \"${l_StrAry[$E_STR_WM_BTL_DIR]}\""
	l_Ary=(`ls -1 "${l_StrAry[$E_STR_WM_BTL_DIR]}"`)
	for l_BottleName in "${l_Ary[@]}"; do
		DbgPrint "${FUNCNAME[0]}: Mounting bottle \"$l_BottleName\""
		BottleMount "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}" "${!l_XdgDsktpSubpathAry}"
		l_RetStat=$?										# Save status
		if [ $l_RetStat -ne $WM_ERR_NONE ];then	# If fail
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	done
																# Enable default bottle
	BottleDefaultEnb "${!l_GlblVarAry}" "${!l_StrAry}" l_BottleName l_WineDirName 
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi
																# Set initialized key
	KeyWr "${l_StrAry[$E_STR_KEY_WM_INIT]}" "1" "${l_StrAry[$E_STR_WM_CONF_FILE]}"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_WM_INIT]}\", Value = \"\", File = \"${l_StrAry[$E_STR_WM_CONF_FILE]}\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Refresh Host XDG
	CustomXdgRefresh "${l_GlblVarAry[$E_GLBL_XDG_REFRESH]}" "${!l_GlblVarAry}"

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*									 	Wine Manager Deinitialize								 *
#*******************************************************************************
#
# Function: Deinitializes Wine Manager system.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2	Strings Array name.
#	Arg3	XDG Directory Array name.
#	Arg4	XDG Subpath Array name.
#
# Output:
#	No variables passed.
#
function WineManagerDeinit ()
{
	local -n l_GlblVarAry="$1"
	local -n l_StrAry="$2"
	local -n l_XdgDirAry="$3"
	local -n l_XdgSubpathAry="$4"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleName=""
	local -a l_Ary

	DbgPrint "${FUNCNAME[0]}: Entered"

	DbgPrint "${FUNCNAME[0]}: Disabling the default bottle"
																# Disable default bottle
	BottleDefaultDsb "${!l_GlblVarAry}" "${!l_StrAry}"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

	DbgPrint "${FUNCNAME[0]}: Unmounting all bottles in \"${l_StrAry[$E_STR_WM_BTL_DIR]}\""
																# If bottle dir exists
	if [ -e "${l_StrAry[$E_STR_WM_BTL_DIR]}" ]; then
		l_Ary=(`ls -1 "${l_StrAry[$E_STR_WM_BTL_DIR]}"`)
		for l_BottleName in "${l_Ary[@]}"; do
			DbgPrint "${FUNCNAME[0]}: Unmounting bottle \"$l_BottleName\""
			BottleUnmount "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}"
			l_RetStat=$?									# Save status
																# If fail
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
				MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		done
	else
		MsgAdd $GC_MSGT_INFO "No bottle directory detected, bottles not deleted." "${!l_GlblVarAry}"
	fi
																# Clear initialized key
	KeyWr "${l_StrAry[$E_STR_KEY_WM_INIT]}" "0" "${l_StrAry[$E_STR_WM_CONF_FILE]}"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_WM_INIT]}\", Value = \"\", File = \"${l_StrAry[$E_STR_WM_CONF_FILE]}\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Refresh host Host XDG
	CustomXdgRefresh "${l_GlblVarAry[$E_GLBL_XDG_REFRESH]}" "${!l_GlblVarAry}"

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*							Wine Manager Environment Variable Verify						 *
#*******************************************************************************
#
# Function: Verifies Wine Manager environment variables.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2  Environment Variable Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function WmVerifyEnvVars()
{
	local -n l_GlblVarAry="$1"
	local -n l_EnvVarAry="$2"
	local l_TmpStr=""
	local l_Name=""
	local l_Type=""
	local l_Opt=""
	local l_Desc=""

	DbgPrint "${FUNCNAME[0]}: Entered."
	for ((i=0; i < ${l_GlblVarAry[$E_GLBL_ENV_VAR_ARY_SIZE]}; i++))
	do
		l_Name="${!l_EnvVarAry[i]:0:1}"				# Env var name
		l_Str="${!l_EnvVarAry[i]:1:1}"				# Type/Optional string
		l_Type="${l_Str:0:1}"							# Type
		l_Opt="${l_Str:1:1}"								# Optional/Manadatory flag
		l_Desc="${!l_EnvVarAry[i]:2:1}"				# Description

		DbgPrint "${FUNCNAME[0]}: Name = \"$l_Name\", Type = \"$l_Type\", Opt = \"$l_Opt\", Desc = \"$l_Desc\"."

		case "$l_Type" in
			d)													# If directory
				DbgPrint "${FUNCNAME[0]}: Directory Verify: Variable = \"$l_Name\"."
				if [[ ! -z "${!l_Name// }" ]]; then	# If var set
					if [ ! -d "${!l_Name}" ]; then	# If dir doesn't exist
						ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"${!l_Name}\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
						return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
					fi
				elif [ "$l_Opt" == "m" ]; then		# If mandatory
					ErrAdd $WM_ERR_ENV_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Variable = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;

			p)													# If path
				DbgPrint "${FUNCNAME[0]}: Path Verify: Variable = \"$l_Name\"."
				if [[ -z "${!l_Name// }" ]]; then	# If var not set
					if [ "$l_Opt" == "m" ]; then		# If mandatory
						ErrAdd $WM_ERR_ENV_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Variable = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
						return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
					fi
				fi
			;;
			
			x)													# If executable
				DbgPrint "${FUNCNAME[0]}: Executable Verify: Variable = \"$l_Name\"."
				if [[ ! -z "${!l_Name// }" ]]; then	# If var set
					l_TmpStr=${!l_Name/% *}				# Get command without args
																# See if it exists
					command -v "$l_TmpStr" >/dev/null 2>&1
					if [ $? -ne 0 ]; then
						ErrAdd $WM_ERR_FILE_NEXEC "${FUNCNAME[0]}${GC_SEP_FTRC}Variable = \"$l_Name\", Command = \"$l_TmpStr\",  Description = \"$l_Desc\"" "${!l_GlblVarAry}"
						return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
					fi
				elif [ "$l_Opt" == "m" ]; then		# If mandatory
					ErrAdd $WM_ERR_ENV_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Variable = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;
		esac
	done

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*								Wine Manager Data Integrity Verify							 *
#*******************************************************************************
#
# Function: Verifies Wine Manager root and bottle directory integrity.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2  Strings Array name.
#	Arg3	Root Directory Array name.
#	Arg4	Bottle Directory Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function WmVerifyData()
{
	local -n l_GlblVarAry="$1"
	local -n l_StrAry="$2"
	local -n l_RootDirAry="$3"
	local -n l_BtlDirAry="$4"
	local l_RetStat=$WM_ERR_NONE
	local l_Answer=""
	local l_BottleName=""
	local l_BottlePathname=""
	local l_ConfFile=""
	local l_Name=""
	local l_Type=""
	local l_Desc=""
	local l_File=""
	local l_Answer=""
	local l_WineExec=""
	local l_TmpStr=""
	local -a l_BtlAry

	DbgPrint "${FUNCNAME[0]}: Entered."

#
# Verify SystemD XDG Monitor Service
# ----------------------------------
																# Create full service name
	l_TmpStr="$ThisHome/.config/systemd/user/${l_StrAry[$E_STR_WM_MON_NAME]}@.service"
	if [ ! -f "$l_TmpStr" ]; then						# If no service

		AskYesNo "${FUNCNAME[0]}${GC_SEP_FTRC}The SystemD XDG Monitor Service \"$l_TmpStr\" doesn't exist, do you want to ignore" l_Answer
		case "$l_Answer" in
			y)											# Yes, add info message
				MsgAdd $GC_MSGT_INFO "Missing SystemD XDG Monitor Service ignored \"$l_TmpStr\"" "${!l_GlblVarAry}"
			;;

			n)											# No
				ErrAdd $WM_ERR_FILE_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}SystemD XDG Monitor Service \"$l_TmpStr\" doesn't exist" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			;;

			*)											# Invalid response from AskYesNo
				ErrAdd $WM_ERR_INV_RESP "${FUNCNAME[0]}${GC_SEP_FTRC}Response = \"$l_Answer\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			;;
		esac
	fi

#
# Verify Wine Manager Root Directory Integrity
# --------------------------------------------
	DbgPrint "${FUNCNAME[0]}: Verifying Wine Manager root directory \"${l_GlblVarAry[$E_GLBL_ROOT]}\" integrity."
	for ((i=0; i < ${l_GlblVarAry[$E_GLBL_ROOT_DIR_ARY_SIZE]}; i++))
	do
		l_Name="${!l_RootDirAry[i]:0:1}"
		l_Type="${!l_RootDirAry[i]:1:1}"
		l_Desc="${!l_RootDirAry[i]:2:1}"

		case "$l_Type" in
			d)													# Directory
				DbgPrint "${FUNCNAME[0]}: Verifying  directory '$l_Name'."
				if [ ! -d "$l_Name" ]; then			# If check failed
					ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;

			f)													# File
				DbgPrint "${FUNCNAME[0]}: Verifying  file '$l_Name'."
				if [ ! -f "$l_Name" ]; then			# If check failed
					ErrAdd $WM_ERR_FILE_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;
			
			*)													# Unknown
				ErrAdd $WM_ERR_UNK_FD_TYPE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Type = \"$l_Type\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			;;
		esac
	done

	l_ConfFile="${l_StrAry[$E_STR_WM_CONF_FILE]}"
																# Verify Wine Manager ID key
	KeyRd "${l_StrAry[$E_STR_KEY_WM_ID]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If fail
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_WM_ID]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Verify Init key
	KeyRd "${l_StrAry[$E_STR_KEY_WM_INIT]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If fail
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_WM_INIT]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Verify Default Bottle name key
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_DFLT]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If fail
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	

#
# Verify Bottle Template
# ----------------------
	for ((i=0; i < ${l_GlblVarAry[$E_GLBL_BTL_DIR_ARY_SIZE]}; i++)); do
		l_Name="${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/${!l_BtlDirAry[i]:0:1}"
		l_Type="${!l_BtlDirAry[i]:1:1}"
		l_Desc="${!l_BtlDirAry[i]:2:1}"

		case "$l_Type" in
			d)													# Directory
				DbgPrint "${FUNCNAME[0]}: Verifying  directory '$l_Name'."
																# If check failed
				if [ ! -d "$l_Name" ]; then
					ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;

			f)													# File
				DbgPrint "${FUNCNAME[0]}: Verifying  file '$l_Name'."
																# If check failed
				if [ ! -f "$l_Name" ]; then
					ErrAdd $WM_ERR_FILE_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			;;

			*)													# Unknown
				ErrAdd $WM_ERR_UNK_FD_TYPE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Type = \"$l_Type\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			;;
		esac
	done

# Verify Bottle Template Configuration Keys
# -----------------------------------------
	l_ConfFile="${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
																# Bottle wine version key
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If fail
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Bottle environment script key
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If fail
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Bottle submenu key
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_SMENU]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If fail
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_SMENU]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
																# Bottle XDG enable key
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If fail
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	

#
# Verify Integrity Of All Bottle Data Directories
# -----------------------------------------------
	DbgPrint "${FUNCNAME[0]}: Verifying integrity of all Wine bottle directories."
	l_BtlAry=(`ls -1 "${l_StrAry[$E_STR_WM_BTL_DIR]}"`)

	for l_BottleName in "${l_BtlAry[@]}"; do
																# Bottle pathname
		l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
																# Bottle conf file
		l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"

		DbgPrint "${FUNCNAME[0]}: Verifying bottle '$l_BottlePathname' directory integrity."
		for ((i=0; i < ${l_GlblVarAry[$E_GLBL_BTL_DIR_ARY_SIZE]}; i++))
		do
			l_Name="$l_BottlePathname/${!l_BtlDirAry[i]:0:1}"
			l_Type="${!l_BtlDirAry[i]:1:1}"
			l_Desc="${!l_BtlDirAry[i]:2:1}"

			case "$l_Type" in
				d)												# Directory
					DbgPrint "${FUNCNAME[0]}: Verifying bottle directory '$l_Name'."
					if [ ! -d "$l_Name" ]; then		# If check failed
						ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
						return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
					fi
				;;
		
				f)												# File
					DbgPrint "${FUNCNAME[0]}: Verifying bottle file '$l_Name'."
					if [ ! -f "$l_Name" ]; then		# If check failed
						ErrAdd $WM_ERR_FILE_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
						return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
					fi
				;;

				*)												# Unknown
					ErrAdd $WM_ERR_UNK_FD_TYPE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_Name\", Type = \"$l_Type\", Description = \"$l_Desc\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				;;
			esac
		done
#
# Wine Directory
		DbgPrint "Reading bottle '$l_BottlePathname' configuration key \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\"."
		KeyRd "${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}" "l_TmpStr" "$l_ConfFile"
		l_RetStat=$?										# Save status
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then	# If fail
																# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi	

		DbgPrint "Verifying bottle '$l_BottlePathname' Wine executable '$l_TmpStr' exists."
			
		l_WineExec="$l_TmpStr/bin/wine"				# Create wine executable name
																# If not null dir and executable doesn't exist
		if [[ ! -z "$l_TmpStr" && ! -x "$l_WineExec" ]]; then
																# If not default wine version
			if [ "$l_TmpStr" != "${l_StrAry[$E_STR_DFLT_WINE_LINK]}" ]; then

				AskYesNo "Wine executable '$l_WineExec' doesn't exist for bottle '$l_BottleName', do you want to ignore" l_Answer
				case "$l_Answer" in
					y)											# Yes, add info message
						MsgAdd $GC_MSGT_INFO "Missing Wine executable ignored \"$l_WineExec\"" "${!l_GlblVarAry}"
					;;

					n)											# No
						ErrAdd $WM_ERR_FILE_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_WineExec\", Bottle = \"$l_BottlePathname\"" "${!l_GlblVarAry}"
						return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
					;;

					*)											# Invalid response from AskYesNo
						ErrAdd $WM_ERR_INV_RESP "${FUNCNAME[0]}${GC_SEP_FTRC}Response = \"$l_Answer\"" "${!l_GlblVarAry}"
						return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
					;;
				esac
			else
				MsgAdd $GC_MSGT_WARN "Bottle \"$l_BottleName\" uses the default wine bottle but there is no default. Use \"default\" command to set default bottle." "${!l_GlblVarAry}"
			fi
		fi
#
# Bottle Environment Script
		KeyRd "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "l_TmpStr" "$l_ConfFile"
		l_RetStat=$?										# Save status
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then	# If fail
																# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi	

		DbgPrint "Verifying bottle '$l_BottlePathname' environment file '$l_TmpStr' exists."
																# If environment file doesn't exist
		if [ ! -z "$l_TmpStr" ] && [ ! -f "$l_TmpStr" ]; then
			AskYesNo "Environment file '$l_TmpStr' doesn't exist for bottle '$l_BottlePathname', do you want to ignore" l_Answer
			case "$l_Answer" in 
				y)												# Yes
					MsgAdd $GC_MSGT_INFO "Missing environment file ignored \"$l_TmpStr\"" "${!l_GlblVarAry}"
				;;

				n)												# No
					ErrAdd $WM_ERR_FILE_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\", Bottle = \"$l_BottlePathname\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				;;

				*)												# Invalid response from AskYesNo
					ErrAdd $WM_ERR_INV_RESP "${FUNCNAME[0]}${GC_SEP_FTRC}Response = \"$l_Answer\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				;;
			esac
		fi
#
# Bottle Submenu
		KeyRd "${l_StrAry[$E_STR_KEY_BTL_SMENU]}" "l_TmpStr" "$l_ConfFile"
		l_RetStat=$?										# Save status
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then	# If fail
																# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_SMENU]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi	
#
# Bottle XDG Enable
		KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_TmpStr" "$l_ConfFile"
		l_RetStat=$?										# Save status
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then	# If fail
																# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi	
	done

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Change Bottle Parameter									 *
#*******************************************************************************
#
# Function: Changes parameter in bottle desktop files and environment.
#
# Input:
#	Arg1	Bottle name.
#	Arg2	Old parameter value.
#	Arg3	New parameter value.
#	Arg4	Global Variable Array name.
#	Arg5	Strings Array name.
#	Arg6	XDG Directory Array name.
#	Arg7	XDG Desktop File Subpath Array name.
#
# Output:
#	Arg4	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#

function BottleParamChange()
{
	local	l_BottlePathname="$1"
	local	l_OldVal="$2"
	local	l_NewVal="$3"
	local -n l_GlblVarAry="$4"
	local -n l_StrAry="$5"
	local -n l_XdgDirAry="$6"
	local -n l_XdgDsktpSubpathAry="$7"
	local l_RetStat=""
	local l_BtlConfFile=""
	local l_BtlEnvFile=""
	local l_FileName=""
	local l_WorkDir=""
	local -a l_SubdirAry

	DbgPrint "${FUNCNAME[0]}: Entered, Bottle pathname = $l_BottlePathname, Old value = \"$l_OldVal\", New Value = \"$l_NewVal\""
																# Get directory subpath for desktop files
	for l_SubdirAry in "${l_XdgDsktpSubpathAry[@]}"
	do
																# Change to desktop directory
		l_WorkDir="$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}/$l_SubdirAry"
		cd "$l_WorkDir"
		DbgPrint "${FUNCNAME[0]}: Changing parameter in all bottle \"$l_WorkDir\" .desktop files"
																# Process all .desktop files
		find . -print | grep -i '.desktop' | while read l_FileName
		do
			DbgPrint "${FUNCNAME[0]}: Changing directory name in desktop file \"$l_WorkDir/$l_FileName\"."
			sed -i 's#'"$l_OldVal"'#'"$l_NewVal"'#g' "$l_WorkDir/$l_FileName"
		done
	done
																# Get bottle conf file pathname
	l_BtlConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
																# Get current env file 
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "l_BtlEnvFile" "$l_BtlConfFile"
	l_RetStat=$?

	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then		# If read fail return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$l_BtlConfFile\"" "${!l_GlblVarAry}"
	elif [ ! -z "$l_BtlEnvFile" ]; then				# If we have an environment file
																# Create new environment file pathname
		l_BtlEnvFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_BIN_DIR]}/${l_StrAry[$E_STR_BTL_ENV_FILE_NAME]}"
		if [ -e "$l_BtlEnvFile" ]; then				# If environment file exists
			DbgPrint "${FUNCNAME[0]}: Changing parameter in environment file \"$l_BtlEnvFile\""
																# Change bottle directory
			sed -i 's#'"$l_OldVal"'#'"$l_NewVal"'#g' "$l_BtlEnvFile"
		fi
																# Write new env file pathname
		KeyWr "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "$l_BtlEnvFile" "$l_BtlConfFile"
		l_RetStat=$?
															
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then	# If write failed
			DbgPrint "${FUNCNAME[0]}: Write key failed with status = \"$l_RetStat\"."
																# If fail create Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", File = \"${l_StrAry[$E_STR_WM_CONF_FILE]}\"" "${!l_GlblVarAry}"
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Default Bottle Enable								 *
#*******************************************************************************
#
# Function: Enables the default bottle.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2  Strings Array name.
#	Arg3	Default bottle name return variable name.
#	Arg4	Default wine version return variable name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleDefaultEnb()
{
	local -n l_GlblVarAry="$1"
	local -n l_StrAry="$2"
	local -n l_DfltBtlName="$3"
	local -n l_DfltWineDir="$4"
	local l_TmpStat=0
	local l_WmConfFile=""
	local l_DfltBtlPathname=""
	local l_DfltBtlConfFile=""
	local l_DfltLnkName=""

	DbgPrint "${FUNCNAME[0]}: Entered."
#
# Get Default Bottle Parameters
#------------------------------
																# Get Wine Manager conf file pathname
	l_WmConfFile="${l_StrAry[$E_STR_WM_CONF_FILE]}"
																# Get default bottle name
	DbgPrint "${FUNCNAME[0]}: About to read key with: KeyRd \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\" \"${!l_DfltBtlName}\" \"$l_WmConfFile\"."
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_DFLT]}" "${!l_DfltBtlName}" "$l_WmConfFile"
	l_TmpStat=$?
	if [ $l_TmpStat -ne $GC_KF_ERR_NONE ];then
																# If fail create Standard Script error code
		DbgPrint "${FUNCNAME[0]}: Read key failed with status = \"$l_TmpStat\"."
		ErrAdd $(($WM_ERR_TOTAL+$l_TmpStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\", File = \"$l_WmConfFile\"" "${!l_GlblVarAry}"
	else
		if [ ! -z "$l_DfltBtlName" ]; then			# If we have a default bottle
																# Get pathname
			l_DfltBtlPathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_DfltBtlName"
																# Get bottle conf file
			l_DfltBtlConfFile="$l_DfltBtlPathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
			DbgPrint "${FUNCNAME[0]}: Default bottle = \"$l_DfltBtlName\", Pathname = \"$l_DfltBtlPathname\", Conf file = \"$l_DfltBtlConfFile\"."
																# Get bottle Wine version
			DbgPrint "${FUNCNAME[0]}: About to read key with: KeyRd \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\" \"l_DfltWineDir\" \"$l_DfltBtlConfFile\"."
			KeyRd "${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}" "${!l_DfltWineDir}" "$l_DfltBtlConfFile"
			l_TmpStat=$?
			if [ $l_TmpStat -ne $GC_KF_ERR_NONE ];then
																# If fail create Standard Script error code
				DbgPrint "${FUNCNAME[0]}: Read key failed with status = \"$l_TmpStat\"."
				ErrAdd $(($WM_ERR_TOTAL+$l_TmpStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$l_DfltBtlConfFile\"" "${!l_GlblVarAry}"
			fi
		else													# If no bottle, delete default
			DbgPrint "${FUNCNAME[0]}: There's no default bottle."
			l_DfltBtlPathname=""
			l_DfltWineDir=""								# No default wine dir
		fi
		DbgPrint "${FUNCNAME[0]}: Default Bottle and Wine Directory Link processing successful."
	fi
#
# Process Default Bottle
#-----------------------
	if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
		DbgPrint "${FUNCNAME[0]}: Bottle pathanme = \"$l_DfltBtlPathname\", Wine version = \"$l_DfltWineDir\"."
		l_DfltLnkName="$ThisHome/.wine"				# Get main wine dir
		DbgPrint "${FUNCNAME[0]}: Main wine version is \"$l_DfltLnkName\"."

		if [ -e "$l_DfltLnkName" ]; then				# If dir exists
			if [ ! -L "$l_DfltLnkName" ]; then		# If it's not a link
																# Set error code and message
				ErrAdd $WM_ERR_LNK_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Default Wine version is not a link: \"$l_DfltLnkName\"" "${!l_GlblVarAry}"
			else
				DbgPrint "${FUNCNAME[0]}: Removing current default Wine link with \"rm $l_DfltLnkName\""
																# Try to delete link
				rm "$l_DfltLnkName" >/dev/null 2>&1
				l_TmpStat=$?
				if [ $l_TmpStat -ne $WM_ERR_NONE ];then
																# If fail set error code and message
					ErrAdd $WM_ERR_LNK_DEL "${FUNCNAME[0]}${GC_SEP_FTRC}Fail status: \"$l_TmpStat\", Link: \"$l_DfltLnkName\"" "${!l_GlblVarAry}"
				fi
			fi
		fi
																# If no error
		if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
																# If new default bottle
			if [ ! -z "$l_DfltBtlPathname" ]; then
																# Link default wine bottle
				DbgPrint "${FUNCNAME[0]}: Adding new default Wine bottle with \"ln -s $l_DfltBtlPathname/wine $l_DfltLnkName\""
				ln -s "$l_DfltBtlPathname/wine" "$l_DfltLnkName" >/dev/null 2>&1
				l_TmpStat=$?
				if [ $l_TmpStat -ne $WM_ERR_NONE ];then
																# If fail set error code and message
					ErrAdd $WM_ERR_LNK_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Fail status: \"$l_TmpStat\", Source: \"$l_DfltBtlPathname/wine\", Link: \"$l_DfltLnkName\"" "${!l_GlblVarAry}"
				fi
			fi
		fi
	fi
#
# Process Wine Directory Link
#----------------------------
	if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
																# If Wine dir link exist
		if [ -e "${l_StrAry[$E_STR_DFLT_WINE_LINK]}" ]; then
																# Try to delete it
			rm "${l_StrAry[$E_STR_DFLT_WINE_LINK]}"
			l_TmpStat=$?
			if [ $l_TmpStat -ne $WM_ERR_NONE ];then
																# If fail set error code and message
				ErrAdd $WM_ERR_LNK_DEL "${FUNCNAME[0]}${GC_SEP_FTRC}Fail status: \"$l_TmpStat\", Link: \"${l_StrAry[$E_STR_DFLT_WINE_LINK]}\"" "${!l_GlblVarAry}"
			fi
		fi
																# If no link or delete successful
		if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
			if [ ! -z "$l_DfltWineDir" ]; then		# If new Wine version link
																# Try to link new Wine version
				DbgPrint "${FUNCNAME[0]}: Adding new default Wine version link with \"ln -s $l_DfltWineDir ${l_StrAry[$E_STR_DFLT_WINE_LINK]}\""
				ln -s "$l_DfltWineDir" "${l_StrAry[$E_STR_DFLT_WINE_LINK]}"
				l_TmpStat=$?
				if [ $l_TmpStat -ne $WM_ERR_NONE ];then
																# If fail set error code and message
					ErrAdd $WM_ERR_LNK_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Source: \"$l_DfltWineDir\", Link: \"${l_StrAry[$E_STR_DFLT_WINE_LINK]}\"" "${!l_GlblVarAry}"
				fi
			fi
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Default Bottle Disable									 *
#*******************************************************************************
#
# Function: Unless the default bottle and default wine version.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2  Strings Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleDefaultDsb()
{
	local -n l_GlblVarAry="$1"
	local -n l_StrAry="$2"
	local l_TmpStat=0
	local l_WmConfFile=""
	local l_DfltBtlName=""
	local l_DfltLnkName=""

	DbgPrint "${FUNCNAME[0]}: Entered."
#
# Get Default Bottle Parameters
#------------------------------
																# Get Wine Manager conf file pathname
	l_WmConfFile="${l_StrAry[$E_STR_WM_CONF_FILE]}"
																# Get default bottle name
	DbgPrint "${FUNCNAME[0]}: About to read key with: KeyRd \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\" \"l_DfltBtlName\" \"$l_WmConfFile\"."
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_DFLT]}" "l_DfltBtlName" "$l_WmConfFile"
	l_TmpStat=$?
	if [ $l_TmpStat -ne $GC_KF_ERR_NONE ];then
																# If fail create Standard Script error code
		DbgPrint "${FUNCNAME[0]}: Read key failed with status = \"$l_TmpStat\"."
		ErrAdd $(($WM_ERR_TOTAL+$l_TmpStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\", File = \"$l_WmConfFile\"" "${!l_GlblVarAry}"
	else
		DbgPrint "${FUNCNAME[0]}: Read default bottle name \"$l_DfltBtlName\" from conf file \"$l_WmConfFile\"."
		if [ ! -z "$l_DfltBtlName" ]; then			# If we have a default bottle
#
# Unlink Default Bottle
#-----------------------
			l_DfltLnkName="$ThisHome/.wine"			# Get main wine dir
			DbgPrint "${FUNCNAME[0]}: Main wine version is \"$l_DfltLnkName\"."

			if [ -e "$l_DfltLnkName" ]; then			# If dir exists
				if [ ! -L "$l_DfltLnkName" ]; then	# If it's not a link
																# Set error code and message
					ErrAdd $WM_ERR_LNK_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Default Wine bottle is not a link: \"$l_DfltLnkName\"" "${!l_GlblVarAry}"
				else
					DbgPrint "${FUNCNAME[0]}: Removing current default Wine bottle link with \"rm $l_DfltLnkName\""
																# Try to delete link
					rm "$l_DfltLnkName" >/dev/null 2>&1
					l_TmpStat=$?
					if [ $l_TmpStat -ne $WM_ERR_NONE ];then
																# If fail set error code and message
						ErrAdd $WM_ERR_LNK_DEL "${FUNCNAME[0]}${GC_SEP_FTRC}Fail status: \"$l_TmpStat\", Link: \"$l_DfltLnkName\"" "${!l_GlblVarAry}"
					fi
				fi
			fi
#
# Unlink Default Wine Directory
#------------------------------
																# If Wine dir link exist
			if [ -e "${l_StrAry[$E_STR_DFLT_WINE_LINK]}" ]; then
				DbgPrint "${FUNCNAME[0]}: Removing current default Wine version link with \"rm ${l_StrAry[$E_STR_DFLT_WINE_LINK]}\""
																# Try to delete it
				rm "${l_StrAry[$E_STR_DFLT_WINE_LINK]}"
				l_TmpStat=$?
				if [ $l_TmpStat -ne $WM_ERR_NONE ];then
																# If fail set error code and message
					ErrAdd $WM_ERR_LNK_DEL "${FUNCNAME[0]}${GC_SEP_FTRC}Fail status: \"$l_TmpStat\", Link: \"${l_StrAry[$E_STR_DFLT_WINE_LINK]}\"" "${!l_GlblVarAry}"
				fi
			fi
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*							Create SystemD XDG Monitor Instance Name						 *
#*******************************************************************************
#
# Function: Creates SystemD XDG Montitor Service instance name. Uses
#				GC_SEP_SYSD_UNIT to seperate bottle name from bottle subpath.
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Strings Array name.
#	Arg3  XDG Directory array variable name.
#	Arg4	Monitor instance name return variable name
#
# Output:
#	Arg4	Monitor instance name.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function XdgMonCreateInstName()
{
	local l_BottleName="$1"
	local -n l_XdgMonCreateInstName_SA="$2"
	local -n l_XdgMonCreateInstName_XDA="$3"
	local -n l_XdgMonCreateInstName_ServiceName="$4"
	local l_RawName=""
	local l_UnitName=""

	DbgPrint "${FUNCNAME[0]}: Entered."

																# Create raw unit suffix
	l_RawName="${l_BottleName}${GC_SEP_SYSD_UNIT}${l_XdgMonCreateInstName_XDA[$E_XDG_PRI_BOTTLE]}/.local/share/applications/wine/Programs"
	DbgPrint "${FUNCNAME[0]}: Raw unit name = \"$l_RawName\"."

	l_UnitName=$(systemd-escape "$l_RawName")		# Create systemd escaped unit suffix
	DbgPrint "${FUNCNAME[0]}: Escaped unit name = \"$l_UnitName\"."
																# Create service name
	l_XdgMonCreateInstName_ServiceName="${l_XdgMonCreateInstName_SA[$E_STR_WM_MON_NAME]}@${l_UnitName}.service"
	DbgPrint "${FUNCNAME[0]}: Escaped service unit name = \"$l_XdgMonCreateInstName_ServiceName\"."

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*								Create SystemD XDG Monitor Service							 *
#*******************************************************************************
#
# Function: Creates SystemD XDG Montitor Service and Script.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2  Strings Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function XdgMonCreateService()
{
	local -n l_XdgMonCreateService_GVA="$1"
	local -n l_XdgMonCreateService_SA="$2"

	DbgPrint "${FUNCNAME[0]}: Entered."

# Create SystemD Monitor Shell Script
# -----------------------------------
	DbgPrint "${FUNCNAME[0]}: Creating SystemD XDG Monitor Script \"${l_XdgMonCreateService_SA[$E_STR_WM_MON_BIN_FILE]}\""

	cat > "${l_XdgMonCreateService_SA[$E_STR_WM_MON_BIN_FILE]}" <<EOL
#!/bin/bash
# Arg1 = SystemD Escaped Bottle Name/Bottle Subpath seperated by '^'
#
l_OldIFS="$IFS"
IFS="^"
ArgsAry=( \$1 )									# Seperate bottle name from subpath 
IFS="$l_OldIFS"
BottleName="\${ArgsAry[0]}"						# Get bottle name
SubPath="\${ArgsAry[1]}"							# Get watch path
WatchPath="\$WINEMGR_ROOT/btl/\$BottleName/\$SubPath"
												# If create failed
if [ ! -d "\$WatchPath" ]; then
	OurName=\`basename "\$0"\`
	echo "\$OurName: ERROR Watch path doesn't exist - \"\$WatchPath\""
	exit 1
fi

echo "Bottle \"\$BottleName\" watch path \"\$WatchPath\" verified, watching for XDG changes ..."
while true
do
	inotifywait -r -e create -e modify -e delete -e move "\${WatchPath}";
	echo "Bottle \"\$BottleName\" watch path \"\$SubPath\" XDG Change Detected, Refreshing ..."
	sleep 1
	winemgr ${GC_STR_ARY[$E_STR_CMD_REFRESH]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} "\$BottleName"
done
EOL
																# If create failed
	if [ ! -f "${l_XdgMonCreateService_SA[$E_STR_WM_MON_BIN_FILE]}" ]; then
		ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"${l_XdgMonCreateService_SA[$E_STR_WM_MON_BIN_FILE]}\"" "${!l_XdgMonCreateService_GVA}"
		return ${l_XdgMonCreateService_GVA[$E_GLBL_ERR_CODE]}
	fi
	chmod a+x "${l_XdgMonCreateService_SA[$E_STR_WM_MON_BIN_FILE]}"

# Create SystemD Monitor Service
# ------------------------------

	DbgPrint "${FUNCNAME[0]}: Creating SystemD XDG Service \"${l_XdgMonCreateService_SA[$E_STR_WM_MON_SRVC_FILE]}\""

	cat > "${l_XdgMonCreateService_SA[$E_STR_WM_MON_SRVC_FILE]}" <<EOL
[Unit]
Description=Wine Manager XDG Change Monitor

[Service]
Type=simple
Environment=ArgsIn=%I
Environment="ExecString=\$WINEMGR_ROOT/bin/${l_XdgMonCreateService_SA[$E_STR_WM_MON_BIN_NAME]}"
ExecStart=/bin/bash -c '\${ExecString} \$ArgsIn'

[Install]
WantedBy=default.target
EOL
																# If create failed
	if [ ! -f "${l_XdgMonCreateService_SA[$E_STR_WM_MON_SRVC_FILE]}" ]; then
		ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"${l_XdgMonCreateService_SA[$E_STR_WM_MON_SRVC_FILE]}\"" "${!l_XdgMonCreateService_GVA}"
	fi
	
	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_XdgMonCreateService_GVA[$E_GLBL_ERR_CODE]}\"."
	return ${l_XdgMonCreateService_GVA[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*								Install SystemD XDG Monitor Service							 *
#*******************************************************************************
#
# Function: Install the SystemD XDG Montitor Service and Script.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2  Strings Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function XdgMonInstall()
{
	local -n l_XdgMonInstall_GVA="$1"
	local -n l_XdgMonInstall_SA="$2"
	local l_RetStat=$WM_ERR_NONE
	local l_SysdDir=""
	local l_TmpStr=""

	DbgPrint "${FUNCNAME[0]}: Entered."

	systemctl --user import-environment				# Always import user environment variable

# Install Wine Manager XDG Change Monitor SystemD Service
# -------------------------------------------------------
																# Create user SystemD dir name
	l_SysdDir="$ThisHome/.config/systemd/user"
	DbgPrint "${FUNCNAME[0]}: Installing Wine Manager XDG Change Monitor SystemD service to \"$l_SysdDir\""
	mkdir -p "$l_SysdDir"								# Create dir if it doesn't exist.
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
		ErrAdd $WM_ERR_DIR_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Status = \"$l_RetStat\", SystemD User Directory = \"$l_SysdDir\"" "${!l_XdgMonInstall_GVA}"
		return ${l_XdgMonInstall_GVA[$E_GLBL_ERR_CODE]}
	fi
																# Create full service name
	l_TmpStr="$ThisHome/.config/systemd/user/${l_XdgMonInstall_SA[$E_STR_WM_MON_NAME]}@.service"

	if [ -f "$l_TmpStr" ]; then						# If existing service
		DbgPrint "${FUNCNAME[0]}: Stopping existing Wine Manager XDG Change Monitor service instances with \"systemctl stop --user \"${l_XdgMonInstall_SA[$E_STR_WM_MON_NAME]}@*\""
																# Stop all existing instances
		systemctl stop --user "${l_XdgMonInstall_SA[$E_STR_WM_MON_NAME]}"'@*'
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# If fail
			DbgPrint "${FUNCNAME[0]}: ERROR - Service stop failed, Status = \"$l_RetStat\"."
			ErrAdd $WM_ERR_SRVC_STOP "${FUNCNAME[0]}${GC_SEP_FTRC}Status = \"$l_RetStat\", Service name = \"${l_XdgMonInstall_SA[$E_STR_WM_MON_NAME]}@*\"" "${!l_XdgMonInstall_GVA}"
			return ${l_XdgMonInstall_GVA[$E_GLBL_ERR_CODE]}
		fi

		DbgPrint "${FUNCNAME[0]}: Disabling existing Wine Manager XDG Change Monitor service instances with \"systemctl disable --user \"${l_XdgMonInstall_SA[$E_STR_WM_MON_NAME]}@.service\""
																# Disable existing service
		systemctl disable --user "${l_XdgMonInstall_SA[$E_STR_WM_MON_NAME]}"'@.service'
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# If fail
			DbgPrint "${FUNCNAME[0]}: ERROR - Service disable failed, Status = \"$l_RetStat\"."
			ErrAdd $WM_ERR_SRVC_DSB "${FUNCNAME[0]}${GC_SEP_FTRC}Status = \"$l_RetStat\", Service name = \"${l_XdgMonInstall_SA[$E_STR_WM_MON_NAME]}@.service\"" "${!l_XdgMonInstall_GVA}"
			return ${l_XdgMonInstall_GVA[$E_GLBL_ERR_CODE]}
		fi
																
		DbgPrint "${FUNCNAME[0]}: Deleting existing Wine Manager XDG Change Monitor service with \"rm $l_TmpStr\""
		rm  "$l_TmpStr" >/dev/null 2>&1				# Delete service
		l_RetStat=$?										# Save status
		if [ $l_RetStat -ne $WM_ERR_NONE ];then	# If fail
			DbgPrint "${FUNCNAME[0]}: ERROR - Service delete failed, Status = \"$l_RetStat\"."
			ErrAdd $WM_ERR_FILE_DEL "${FUNCNAME[0]}${GC_SEP_FTRC}Status = \"$l_RetStat\", Service name = \"$l_TmpStr\"" "${!l_XdgMonInstall_GVA}"
			return ${l_XdgMonInstall_GVA[$E_GLBL_ERR_CODE]}
		fi
	fi
																# Install service
	DbgPrint "${FUNCNAME[0]}: Copying Wine Manager XDG Change Monitor service with \"cp ${l_XdgMonInstall_SA[$E_STR_WM_MON_SRVC_FILE]} $l_SysdDir\""
	cp "${l_XdgMonInstall_SA[$E_STR_WM_MON_SRVC_FILE]}" "$l_SysdDir" >/dev/null 2>&1
																# If install failed
	if [ ! -f "$l_SysdDir/${l_XdgMonInstall_SA[$E_STR_WM_MON_SRVC_NAME]}" ]; then
		DbgPrint "${FUNCNAME[0]}: ERROR - Service create failed."
		ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Service = \"$l_SysdDir/${l_XdgMonInstall_SA[$E_STR_WM_MON_SRVC_NAME]}\"" "${!l_XdgMonInstall_GVA}"
		return ${l_XdgMonInstall_GVA[$E_GLBL_ERR_CODE]}
	fi

	DbgPrint "${FUNCNAME[0]}: Reloading SystemD User Units"
	systemctl daemon-reload --user					# Reload SystemD units
	l_RetStat=$?											# Save status
	if [ $l_RetStat -ne $WM_ERR_NONE ];then		# If fail
		DbgPrint "${FUNCNAME[0]}: ERROR - Service reload failed."
		ErrAdd $WM_ERR_SRVC_RELD "${FUNCNAME[0]}${GC_SEP_FTRC}Status = \"$l_RetStat\", Service reload command = \"systemctl daemon-reload --user\"" "${!l_XdgMonInstall_GVA}"
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_XdgMonInstall_GVA[$E_GLBL_ERR_CODE]}\"."
	return ${l_XdgMonInstall_GVA[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Merge Mount XDG										 *
#*******************************************************************************
#
# Function: Creates a merge mount for all directories in the XDG directory array.
#
# Input:
#	Arg1	XDG directory
#	Arg2	XDG merge mount point
#	Arg3	Global Variable Array name.
#	Arg4	XDG Subpath Array name.
#
# Output:
#	Arg3	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function MergeMountXdg()
{
	local l_Dir="$1"
	local l_MountPoint="$2"
   local l_Mode="$3"
	local -n l_GlblVarAry="$4"
	local -n l_XdgSubpathAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_RetStat2=$WM_ERR_NONE
	local l_DirAbsPath=""
	local l_MountPointAbsPath=""
	
	DbgPrint "${FUNCNAME[0]}: Entered with Directory=\"$l_Dir\", Mount Point=\"$l_MountPoint\", Mode = \"$l_Mode\""

	for l_XdgDir in "${l_XdgSubpathAry[@]}"
	do
		GetAbsPath "$l_Dir/$l_XdgDir" "l_DirAbsPath"
		l_RetStat=$?											# Save status
		GetAbsPath "$l_MountPoint/$l_XdgDir" "l_MountPointAbsPath"
		l_RetStat2=$?											# Save status
		if [[ $l_RetStat -eq $WM_ERR_NONE && $l_RetStat2 -eq $WM_ERR_NONE ]];then
			DbgPrint "${FUNCNAME[0]}:Directory absolute path - \"$l_DirAbsPath\""
			DbgPrint "${FUNCNAME[0]}: Mount point absolute path - \"$l_MountPointAbsPath\""
			DbgPrint "${FUNCNAME[0]}: First unmounting with 'fusermount -uq \"$l_MountPointAbsPath\"'"
			fusermount -uq "$l_MountPointAbsPath"		# Clear merge mount

			DbgPrint "${FUNCNAME[0]}: Now merge mounting with \"mergerfs -o defaults,allow_other,direct_io,use_ino,hard_remove,category.create=mfs,fsname=mergerfs $l_DirAbsPath=$l_Mode $l_MountPointAbsPath\""
			mergerfs -o defaults,allow_other,direct_io,use_ino,hard_remove,category.create=mfs,fsname=mergerfs "$l_DirAbsPath=$l_Mode" "$l_MountPointAbsPath"
		else													# If we couldn't get absolute paths
			DbgPrint "${FUNCNAME[0]}: ERROR - Couldn't get absolute path for \"$l_Dir/$l_XdgDir\" or \"$l_MountPoint/$l_XdgDir\""

			ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}XDG directory = \"$l_Dir/$l_XdgDir\", Mount point = \"$l_MountPoint/$l_XdgDir\"" "${!l_GlblVarAry}"
			break
		fi
	done
	
	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Merge Unmount XDG										 *
#*******************************************************************************
#
# Function: Merge unmounts all directories in the XDG directory array.
#
# Input:
#	Arg1	XDG merge mount point
#	Arg2	Global Variable Array name.
#	Arg3	XDG Subpath Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function MergeUnmountXdg()
{
	local l_MountPoint="$1"
  	local -n l_GlblVarAry="$2"
	local -n l_XdgSubpathAry="$3"
	local l_RetStat=$WM_ERR_NONE
	local l_MountPointAbsPath=""
	
	DbgPrint "${FUNCNAME[0]}: Entered with Mount Point=\"$l_MountPoint\""

	for l_XdgDir in "${l_XdgSubpathAry[@]}"
	do
		GetAbsPath "$l_MountPoint/$l_XdgDir" "l_MountPointAbsPath"
		l_RetStat=$?										# Save status
		if [ $l_RetStat -eq $WM_ERR_NONE ];then
			DbgPrint "${FUNCNAME[0]}: Mount point absolute path - \"$l_MountPointAbsPath\""
																# If mergerfs
			if [ -f "$l_MountPointAbsPath/.mergerfs" ]; then
																# Clear merge mount
				DbgPrint "${FUNCNAME[0]}: Unmounting with 'fusermount -uq \"$l_MountPointAbsPath\"'"
				fusermount -uq "$l_MountPointAbsPath"
			else												# If not a merger file system
				DbgPrint "${FUNCNAME[0]}: ERROR - Not a merge filesystem \"$l_MountPointAbsPath\""
				ErrAdd $WM_ERR_DIR_NMERGE "${FUNCNAME[0]}${GC_SEP_FTRC}Mount point absolute path = \"$l_MountPointAbsPath\"" "${!l_GlblVarAry}"
				break
			fi
		else													# If we couldn't get absolute paths
			DbgPrint "${FUNCNAME[0]}: ERROR - Couldn't get absolute path for \"$l_MountPoint/$l_XdgDir\""
			ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Mount point = \"$l_MountPoint/$l_XdgDir\"" "${!l_GlblVarAry}"
			break
		fi
	done
	
	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Delete XDG Data										 *
#*******************************************************************************
#
# Function: Deletes data in all directories in the XDG directory array.
#
# Input:
#	Arg1	XDG root directory
#	Arg2	Global Variable Array name.
#	Arg3	XDG Subpath Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function DeleteXdgData ()
{
	local l_XdgRoot="$1"
	local -n l_GlblVarAry="$2"
	local -n l_XdgSubpathAry="$3"
	local l_XdgDir=""
	local l_XdgPathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with l_XdgRoot=\"$l_XdgRoot\""

	for l_XdgDir in "${l_XdgSubpathAry[@]}"
	do
		l_XdgPathname="$l_XdgRoot/$l_XdgDir"
		DbgPrint "${FUNCNAME[0]}: Checking if \"$l_XdgPathname\" exists"
		if [ -d "$l_XdgPathname" ]; then
			DbgPrint "${FUNCNAME[0]}: Deleting all \"$l_XdgPathname\" data"
																# Delete all XDG data
			find "$l_XdgPathname/." -name . -o -prune -exec rm -rf -- {} +
		else													# If directory doesn't exist
			ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}XDG directory = \"$l_XdgPathname\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	done

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*												Bottle Mount										 *
#*******************************************************************************
#
# Function: Mounts bottle.
#
# Input:
#	Arg1	Bottle name.
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg4	XDG Directory Array name.
#	Arg5	XDG Subpath Array name.
#	Arg6	XDG Desktop File Subpath Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleMount ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local -n l_XdgDsktpSubpathAry="$6"
	local l_RetStat=$WM_ERR_NONE
	local l_BottlePathname=""
	local l_ConfFile=""
	local l_TmpStr=""
	local -a l_BranchNameAry_BM=()

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\""
																# Bottle pathname
	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
																# Bottle conf file
	l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"

																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
																# Merge mount Private Bottle XDG to Bottle Muliplexer XDG
		DbgPrint "${FUNCNAME[0]}: Merge mounting Private Bottle XDG \"$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}\" to Bottle Multiplexer XDG \"$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}\""
		MergeMountXdg "$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}" "$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}" "RW" "${!l_GlblVarAry}" "${!l_XdgSubpathAry}"
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
																# Merge add Private Host XDG to Bottle Multiplexer XDG in RO mode
		DbgPrint "${FUNCNAME[0]}: Merge adding Private Host XDG \"${l_GlblVarAry[$E_GLBL_XDG_PRI_HOST]}\" to Bottle Multiplexer XDG \"$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}\" in RO mode"
		l_BranchNameAry_BM=( "${l_GlblVarAry[$E_GLBL_XDG_PRI_HOST]}" )
		MergeAddXdg "RO" "$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}" l_BranchNameAry_BM "${!l_XdgSubpathAry}" "${!l_GlblVarAry}"
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	fi
																# Get Bottle XDG enable key
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	

	if [ $l_TmpStr -eq $GC_BTL_XDG_ENB ]; then	# If bottle XDG enabled
		DbgPrint "${FUNCNAME[0]}: Mounting XDG for bottle \"$l_BottleName\""
		l_BranchNameAry_BM=( "$l_BottleName" )		# Mount XDG
		BottleMountHostXdg l_BranchNameAry_BM "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}" "${!l_XdgDsktpSubpathAry}"
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*												Bottle Unmount										 *
#*******************************************************************************
#
# Function: Unmounts bottle.
#
# Input:
#	Arg1	Bottle name
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg4	XDG Directory Array name.
#	Arg5	XDG Subpath Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleUnmount ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_BottlePathname=""
	local l_ConfFile=""
	local l_TmpStr=""
	local -a l_BranchNameAry_BU=()

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\""

																# Bottle pathname
	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
	DbgPrint "${FUNCNAME[0]}: Bottle pathname = \"$l_BottlePathname\""
																# Bottle conf file
	l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
	DbgPrint "${FUNCNAME[0]}: Bottle conf file = \"$l_ConfFile\""
																# Get Bottle XDG enable key
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_TmpStr" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
	DbgPrint "${FUNCNAME[0]}: Read key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", Value = \"$l_TmpStr\", Conf file = \"$l_ConfFile\""
	if [ $l_TmpStr -eq $GC_BTL_XDG_ENB ]; then	# If bottle XDG enabled
		DbgPrint "${FUNCNAME[0]}: Unmunting XDG for bottle \"$l_BottleName\""
		l_BranchNameAry_BU=( "$l_BottleName" )		# Unmount XDG
		BottleUnmountHostXdg l_BranchNameAry_BU "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}"
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	fi
																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
																# Merge remove Private Host XDG from Bottle Multiplexer XDG
		DbgPrint "${FUNCNAME[0]}: Merge removing Private XDG \"${l_GlblVarAry[$E_GLBL_XDG_PRI_HOST]}\" from Bottle Multiplexer XDG \"$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}\""
		l_BranchNameAry_BU=( "${l_GlblVarAry[$E_GLBL_XDG_PRI_HOST]}" )
		MergeRemoveXdg "$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}" l_BranchNameAry_BU "${!l_XdgSubpathAry}" "${!l_GlblVarAry}"
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
			DbgPrint "${FUNCNAME[0]}: Merge removing Private Host Read Only XDG failed"
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	
																# Merge unmount Private Bottle XDG from Bottle Muliplexer XDG
		DbgPrint "${FUNCNAME[0]}: Merge unmounting Bottle Multiplexer XDG \"$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}\""
		MergeUnmountXdg "$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_MUX]}" "${!l_GlblVarAry}" "${!l_XdgSubpathAry}"
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										  Bottle Enable Host XDG								 *
#*******************************************************************************
#
# Input:
#	Arg1	Full bottle pathname
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg4	XDG Directory Array name.
#	Arg5	XDG Subpath Array name.
#	Arg6	XDG Desktop File Subpath Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleHostXdgEnb ()
{
	local -n l_BottleNameAryIn="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local -n l_XdgDsktpSubpathAry="$6"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleName=""
	local l_ConfFile=""
	local l_TmpStr=""
	local -a l_BottleNameAry_BHXE=()

	DbgPrint "${FUNCNAME[0]}: Entered with Bottle Name Array name \"${!l_BottleNameAryIn}\""

#
# Remove already disabled bottles from bottle name array
	for l_BottleName in "${l_BottleNameAryIn[@]}"	
	do
		l_ConfFile="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
		DbgPrint "${FUNCNAME[0]}: Conf file = \"$l_ConfFile\""

		KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_TmpStr" "$l_ConfFile"
		l_RetStat=$?
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
			break
		fi
																# If Host XDG already enabled
		if [ $l_TmpStr -eq $GC_BTL_XDG_ENB ]; then
			MsgAdd $GC_MSGT_WARN "Bottle \"$l_BottleName\" XDG is already enabled" "${!l_GlblVarAry}"
		else													# Otherwise add to final bottle name array
			l_BottleNameAry_BHXE+=("$l_BottleName")
		fi
	done

#
# Mount XDGs and set XDG status to enabled
	if [[ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ${#l_BottleNameAry_BHXE[@]} -gt 0 ]]; then

		if ! BottleMountHostXdg l_BottleNameAry_BHXE "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}" "${!l_XdgDsktpSubpathAry}"; then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		else
																# Write XDG enable to bottle configs
			for l_BottleName in "${l_BottleNameAry_BHXE[@]}"
			do
				KeyWr "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "$GC_BTL_XDG_ENB" "${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
				l_RetStat=$?
				if [ $l_RetStat -eq $GC_KF_ERR_NONE ];then
																# Create XDG disable menu entry
					if BottleWmMenuAddXdgDsb "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"; then
						MsgAdd $GC_MSGT_SUCCESS "Bottle \"$l_BottleName\" XDG enabled" "${!l_GlblVarAry}"
					fi
				else
																# Return Standard Script error code
					ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", Value = \"$GC_BTL_XDG_DSB\", File = \"${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_StrAry[$E_STR_BTL_CONF_FILE]}\"" "${!l_GlblVarAry}"
					break
				fi
			done
		fi
	fi	

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Bottle Mount Host XDG								 *
#*******************************************************************************
#
# Function: Mounts the Bottle XDG on the Host Multiplexer XDG.
#
# Input:
#	Arg1	Full bottle pathname
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg5	XDG Directory Array name.
#	Arg5	XDG Subpath Array name.
#	Arg6	XDG Desktop File Subpath Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleMountHostXdg ()
{
	local -n l_BottleNameAry="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local -n l_XdgDsktpSubpathAry="$6"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleName=""
	local l_ServiceName=""
	local -a l_BranchPathAry=()

	DbgPrint "${FUNCNAME[0]}: Entered with Bottle Name Array name \"${!l_BottleNameAry}\""

#
# Create all bottle translate XDGs
	for l_BottleName in "${l_BottleNameAry[@]}"	
	do
																# Build bottle translate XDG
		if ! BuildTranslateXDG "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}" "${!l_XdgDsktpSubpathAry}"; then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			break
		fi
	done

#
# Mount all XDG branches
																# If no error
	if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
		for l_BottleName in "${l_BottleNameAry[@]}"	
		do														# Create branch path array
			l_BranchPathAry+=( "${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_XdgDirAry[$E_XDG_PRI_BOTTLE_TRANS]}" )
		done

		if ! MergeAddXdg "RO" "${l_GlblVarAry[$E_GLBL_XDG_HOST_MUX]}" l_BranchPathAry "${!l_XdgSubpathAry}" "${!l_GlblVarAry}"; then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			break
		fi
	fi

#
# Start all SystemD bottle monitors
																# If no error
	if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
		systemctl --user import-environment			# Always import user environment variables

		for l_BottleName in "${l_BottleNameAry[@]}"	
		do
																# Create service name
			XdgMonCreateInstName "$l_BottleName" "${!l_StrAry}" "${!l_XdgDirAry}" l_ServiceName
																# Start Wine Manager XDG Change Monitor
			DbgPrint "${FUNCNAME[0]}: Starting Wine Manager XDG Change Monitor with \"systemctl start --user $l_ServiceName\""
			systemctl start --user "$l_ServiceName"
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Set error code and message
				DbgPrint "${FUNCNAME[0]}: ERROR - Service start failed."
				ErrAdd $WM_ERR_SRVC_START "${FUNCNAME[0]}${GC_SEP_FTRC}Status = \"$l_RetStat\", Service name = $l_ServiceName" "${!l_GlblVarAry}"
				break
			fi
		done
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*												Merge Add XDG										 *
#*******************************************************************************
#
# Function: Adds a merge mount for all directories in the XDG directory array.
#
# Input:
#	Arg1	RO/RW Mode
#	Arg2	Merge mount point
#	Arg3	Branch path array
#	Arg4	XDG Subpath Array name.
#	Arg5	Global Variable Array name.
#
# Output:
#	Arg5	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function MergeAddXdg()
{
   local l_Mode="$1"
	local l_MergeRoot="$2"
	local -n l_BranchPathAry_MAX="$3"
	local -n l_XdgSubpathAry="$4"
	local -n l_GlblVarAry="$5"
	local l_XdgSubpath=""
	local l_BranchPath=""
	local l_MountBranch=""
	local -a l_MountBranchAry=()
	
	DbgPrint "${FUNCNAME[0]}: Entered with Mode = \"$l_Mode\", Merge Root = \"$l_MergeRoot\", Bottle Name Array =\"${!l_BranchPathAry_MAX}\""
																# Create branch mount array for each XDG subpath
	for l_XdgSubpath in "${l_XdgSubpathAry[@]}"
	do
		l_MountBranchAry=()								# Clear mount array
																# Create branch mount array for all bottles with this subpath
		for l_BranchPath in "${l_BranchPathAry_MAX[@]}"
		do
			l_MountBranch="$l_BranchPath/$l_XdgSubpath"
			DbgPrint "${FUNCNAME[0]}: Adding to Branch Unmount Array - \"$l_MountBranch\"."
			l_MountBranchAry+=( "$l_MountBranch" )
		done
																# Add branches to mount point
		if ! MergeAddBranches "$l_Mode" "$l_MergeRoot/$l_XdgSubpath" l_MountBranchAry "${!l_GlblVarAry}"; then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			break
		fi
	done

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*												Merge Add Branches								 *
#*******************************************************************************
#
# Function: Add branches to a merge mount.
#
# Input:
#	Arg1	Merge path (i.e. "/home/phalynx/.config", "/home/phalynx/.winemgr/btl/music64.wine/xdg/bottle_mux/,config")
#	Arg2	Branch path array name (i.e. array of "/home/phalynx/.winemgr/btl/games64.wine/xdg/pri_bottle_translate/.config", "/home/phalynx/.winemgr/btl/music64.wine/xdg/pri_bottle_translate/.config", or "/home/phalynx/.winemgr_xdg_host/.config" 
#	Arg3	Global Variable Array name.
#
# Output:
#	Arg3	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function MergeAddBranches()
{
   local l_Mode="$1"
	local l_MergePath="$2"
	local -n l_BranchPathAry="$3"
	local -n l_GlblVarAry="$4"
	local l_RetStat=0
	local l_MergeAbsPath=""
	local l_BranchRoot=""
	local l_BranchAbsPath=""
	local l_MountStr=""
	local l_TmpStr=""
	local l_OldIFS=""
	local l_FoundFlg=0
	local -a l_CurrMountAry=()
	
	DbgPrint "${FUNCNAME[0]}: Entered with Mode = \"$l_Mode\", Merge Path=\"$l_MergePath\", Branch Path Array name = \"${!l_BranchPathAry}\""
																# If we can't get merge absolute mount point
	if ! GetAbsPath "$l_MergePath" "l_MergeAbsPath"; then
		DbgPrint "${FUNCNAME[0]}: ERROR - Couldn't get merge absolute path for \"$l_MergePath\""
		ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}XDG directory = Mount point = \"$l_MergePath\"" "${!l_GlblVarAry}"
																# If not a merger file system
	elif [ ! -f "$l_MergeAbsPath/.mergerfs" ]; then
		DbgPrint "${FUNCNAME[0]}: ERROR - Not a merge filesystem \"$l_MergeAbsPath\""
		ErrAdd $WM_ERR_DIR_NMERGE "${FUNCNAME[0]}${GC_SEP_FTRC}Mount point absolute path = \"$l_MergeAbsPath\"" "${!l_GlblVarAry}"
	else
		DbgPrint "${FUNCNAME[0]}: Merge absolute path - \"$l_MergeAbsPath\""
																# Get current branch mounts
		l_TmpStr=`xattr -p user.mergerfs.srcmounts "$l_MergeAbsPath/.mergerfs"`
		DbgPrint "${FUNCNAME[0]}: Current merge mounts - \"$l_TmpStr\""
		l_OldIFS="$IFS"
		IFS=":"
		l_CurrMountAry=( $l_TmpStr )					# Break into seperate strings
		IFS="$l_OldIFS"
																# Process all branches
		for l_BranchRoot in "${l_BranchPathAry[@]}"
		do
																# If we can't get absolute branch path 
			if ! GetAbsPath "$l_BranchRoot" "l_BranchAbsPath"; then
				DbgPrint "${FUNCNAME[0]}: ERROR - Couldn't get absolute path for \"$l_BranchRoot\""
				ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}XDG directory = \"$l_BranchRoot\"" "${!l_GlblVarAry}"
				break
			else												# If we got absolute path
				DbgPrint "${FUNCNAME[0]}: Branch XDG absolute path - \"$l_BranchAbsPath\""
																# Search all current mount strings
				DbgPrint "${FUNCNAME[0]}: Searching all current mount strings for existing \"$l_BranchAbsPath\" ..."
				l_FoundFlg=0
				for l_TmpStr in "${l_CurrMountAry[@]}"
				do
					DbgPrint "${FUNCNAME[0]}: Comparing current mount string \"$l_TmpStr\""
																# If branch already mounted
					if [[ "$l_TmpStr" == "$l_BranchAbsPath" ]]; then
						DbgPrint "${FUNCNAME[0]}: Branch is currently mounted - \"$l_BranchAbsPath\""
						l_FoundFlg=1						# Set found flag
						break									# Break out of loop
					fi
				done

				if [ $l_FoundFlg -eq 0 ]; then		# If branch not found
																# Add to mount string
					DbgPrint "${FUNCNAME[0]}: Adding \"$l_BranchAbsPath\" to mount string"
					if [ ! -z "$l_MountStr" ]; then	# If previous entry
						l_MountStr="${l_MountStr}:"	# Add seperator
					fi
					l_MountStr="${l_MountStr}${l_BranchAbsPath}=$l_Mode"
				else
					DbgPrint "${FUNCNAME[0]}: Branch already mounted - \"$l_BranchAbsPath\""
					MsgAdd $GC_MSGT_WARN "Branch \"$l_BranchAbsPath\" already mounted to \"$l_MergeAbsPath\"." "${!l_GlblVarAry}"
				fi
			fi
		done
																# If no error and mounts
		if [[ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ! -z "$l_MountStr" ]]; then
																# Mount branches
			DbgPrint "${FUNCNAME[0]}: Merge adding with 'xattr -w user.mergerfs.srcmounts \"+>$l_MountStr\" \"$l_MergeAbsPath/.mergerfs\""
			xattr -w user.mergerfs.srcmounts "+>$l_MountStr" "$l_MergeAbsPath/.mergerfs"
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Bottle Disable Host XDG									 *
#*******************************************************************************
#
# Function: Unmounts the Bottle XDG from the Host Multiplexer XDG, set its XDG
#				config to disabled, and optionally refreshes the Host XDG.
#
# Input:
#	Arg1	Bottle Name Array name.
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg4	XDG Path Array name.
#	Arg5	XDG Directory Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleHostXdgDsb ()
{
	local -n l_BottleNameAryIn="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleName=""
	local l_ConfFile=""
	local l_TmpStr=""
	local -a l_BottleNameAry_BHXD=()

	DbgPrint "${FUNCNAME[0]}: Entered with Bottle Name Array name \"${!l_BottleNameAryIn}\""

#
# Remove already disabled bottles from bottle name array
	for l_BottleName in "${l_BottleNameAryIn[@]}"	
	do
		l_ConfFile="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
		DbgPrint "${FUNCNAME[0]}: Conf file = \"$l_ConfFile\""

		KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_TmpStr" "$l_ConfFile"
		l_RetStat=$?
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
			break
		fi
																# If Host XDG already disabled
		if [ $l_TmpStr -eq $GC_BTL_XDG_DSB ]; then
			MsgAdd $GC_MSGT_WARN "Bottle \"$l_BottleName\" XDG is already disabled" "${!l_GlblVarAry}"
		else													# Otherwise add to final bottle name array
			l_BottleNameAry_BHXD+=("$l_BottleName")
		fi
	done

#
# Unmount XDGs and set XDG status to disabled
	if [[ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ${#l_BottleNameAry_BHXD[@]} -gt 0 ]]; then

		if ! BottleUnmountHostXdg l_BottleNameAry_BHXD "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}"; then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		else
																# Write XDG disable to bottle configs
			for l_BottleName in "${l_BottleNameAry_BHXD[@]}"
			do
				KeyWr "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "$GC_BTL_XDG_DSB" "${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
				l_RetStat=$?
				if [ $l_RetStat -eq $GC_KF_ERR_NONE ];then
																# Create XDG enable menu entry
					if BottleWmMenuAddXdgEnb "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"; then
						MsgAdd $GC_MSGT_SUCCESS "Bottle \"$l_BottleName\" XDG disabled" "${!l_GlblVarAry}"
					fi
				else
																# Return Standard Script error code
					ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", Value = \"$GC_BTL_XDG_DSB\", File = \"${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_StrAry[$E_STR_BTL_CONF_FILE]}\"" "${!l_GlblVarAry}"
					break
				fi
			done
		fi
	fi	

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Bottle Unmount Host XDG									 *
#*******************************************************************************
#
# Function: Unmounts the Bottle XDG from the Host Multiplexer XDG.
#
# Input:
#	Arg1	 Bottle name.
#	Arg2	 Global Variable Array name.
#	Arg3	 Strings Array name.
#	Arg4	 XDG Path Array name.
#	Arg5	 XDG Directory Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleUnmountHostXdg ()
{
	local -n l_BottleNameAry="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleName=""
	local l_ServiceName=""
	local -a l_BranchPathAry=()

	DbgPrint "${FUNCNAME[0]}: Entered with Bottle Name Array name \"${!l_BottleNameAry}\""
#
# Stop all SystemD bottle monitors
	for l_BottleName in "${l_BottleNameAry[@]}"	
	do
																# Create service unit name
		XdgMonCreateInstName "$l_BottleName" "${!l_StrAry}" "${!l_XdgDirAry}" l_ServiceName
		DbgPrint "${FUNCNAME[0]}: Stopping Wine Manager XDG Change Monitor with \"systemctl stop --user $l_ServiceName\""
		systemctl stop --user "$l_ServiceName"
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Set error code and message
			DbgPrint "${FUNCNAME[0]}: ERROR - Service stop failed."
			ErrAdd $WM_ERR_SRVC_STOP "${FUNCNAME[0]}${GC_SEP_FTRC}Status = \"$l_RetStat\", Service name = $l_ServiceName" "${!l_GlblVarAry}"
			break
		fi
	done
#
# Unmount all XDG branches
																# If no error
	if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
		for l_BottleName in "${l_BottleNameAry[@]}"	
		do														# Create branch path array
			l_BranchPathAry+=( "${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName/${l_XdgDirAry[$E_XDG_PRI_BOTTLE_TRANS]}" )
		done

		if ! MergeRemoveXdg "${l_GlblVarAry[$E_GLBL_XDG_HOST_MUX]}" l_BranchPathAry "${!l_XdgSubpathAry}" "${!l_GlblVarAry}"; then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Merge Remove XDG										 *
#*******************************************************************************
#
# Function: Removes a merge mount for all directories in the XDG subpath array.
#
# Input:
#	Arg1	Merge point root
#	Arg2	Bottle Name Array name
#	Arg3	XDG Subpath Array name.
#	Arg4	Global Variable Array name.
#
# Output:
#	Arg3	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function MergeRemoveXdg()
{
	local l_MergeRoot="$1"
	local -n l_BranchPathAry_MRX="$2"
	local -n l_XdgSubpathAry="$3"
	local -n l_GlblVarAry="$4"
	local l_XdgSubpath=""
	local l_BranchPath=""
	local l_UmountBranch=""
	local -a l_UmountBranchAry=()
	
	DbgPrint "${FUNCNAME[0]}: Entered with Merge Root = \"$l_MergeRoot\", Branch Path Array Name = \"${!l_BranchPathAry_MRX}\""
																# Create branch unmount array for each XDG subpath
	for l_XdgSubpath in "${l_XdgSubpathAry[@]}"
	do
		l_UmountBranchAry=()								# Clear unmount array
																# Create branch unmount array for all bottles with this subpath
		for l_BranchPath in "${l_BranchPathAry_MRX[@]}"
		do
			l_UmountBranch="$l_BranchPath/$l_XdgSubpath"
			DbgPrint "${FUNCNAME[0]}: Adding to Branch Unmount Array - \"$l_UmountBranch\"."
			l_UmountBranchAry+=( "$l_UmountBranch" )
		done
																# Remove branches from mount point
		if ! MergeRemoveBranches "$l_MergeRoot/$l_XdgSubpath" l_UmountBranchAry "${!l_GlblVarAry}"; then
																# Prepend function name to error message
			MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
			break
		fi
	done

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Merge Remove Branches								 *
#*******************************************************************************
#
# Function: Removes branches from a merge mount.
#
# Input:
#	Arg1	Merge path (i.e. "/home/phalynx/.config", "/home/phalynx/.winemgr/btl/music64.wine/xdg/bottle_mux/,config")
#	Arg2	Branch path array name (i.e. array of "/home/phalynx/.winemgr/btl/games64.wine/xdg/pri_bottle_translate/.config", "/home/phalynx/.winemgr/btl/music64.wine/xdg/pri_bottle_translate/.config", or "/home/phalynx/.winemgr_xdg_host/.config" 
#	Arg3	Global Variable Array name.
#
# Output:
#	Arg4	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function MergeRemoveBranches()
{
	local l_MergePath="$1"
	local -n l_BranchPathAry="$2"
	local -n l_GlblVarAry="$3"
	local l_RetStat=0
	local l_MergeAbsPath=""
	local l_BranchRoot=""
	local l_BranchAbsPath=""
	local l_UmountStr=""
	local l_TmpStr=""
	local l_OldIFS=""
	local l_FoundFlg=0
	local -a l_CurrMountAry=()
	
	DbgPrint "${FUNCNAME[0]}: Entered with Merge Path=\"$l_MergePath\", Branch Path Array name = \"${!l_BranchPathAry}\""
																# If we can't get merge absolute mount point
	if ! GetAbsPath "$l_MergePath" "l_MergeAbsPath"; then
		DbgPrint "${FUNCNAME[0]}: ERROR - Couldn't get merge absolute path for \"$l_MergePath\""
		ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}XDG directory = Mount point = \"$l_MergePath\"" "${!l_GlblVarAry}"
																# If not a merger file system
	elif [ ! -f "$l_MergeAbsPath/.mergerfs" ]; then
		DbgPrint "${FUNCNAME[0]}: ERROR - Not a merge filesystem \"$l_MergeAbsPath\""
		ErrAdd $WM_ERR_DIR_NMERGE "${FUNCNAME[0]}${GC_SEP_FTRC}Mount point absolute path = \"$l_MergeAbsPath\"" "${!l_GlblVarAry}"
	else
		DbgPrint "${FUNCNAME[0]}: Merge absolute path - \"$l_MergeAbsPath\""
																# Get current branch mounts
		l_TmpStr=`xattr -p user.mergerfs.srcmounts "$l_MergeAbsPath/.mergerfs"`
		DbgPrint "${FUNCNAME[0]}: Current merge mounts - \"$l_TmpStr\""

		l_OldIFS="$IFS"
		IFS=":"
		l_CurrMountAry=( $l_TmpStr )					# Break into seperate strings
		IFS="$l_OldIFS"
																# Process all branches
		for l_BranchRoot in "${l_BranchPathAry[@]}"
		do
																# If we can't get absolute branch path 
			if ! GetAbsPath "$l_BranchRoot" "l_BranchAbsPath"; then
				DbgPrint "${FUNCNAME[0]}: ERROR - Couldn't get absolute path for \"$l_BranchRoot\""
				ErrAdd $WM_ERR_DIR_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}XDG directory = \"$l_BranchRoot\"" "${!l_GlblVarAry}"
				break
			else												# If we got absolute path
				DbgPrint "${FUNCNAME[0]}: Branch XDG absolute path - \"$l_BranchAbsPath\""
																# Search all current mount strings
				DbgPrint "${FUNCNAME[0]}: Searching all current mount strings for existing \"$l_BranchAbsPath\" ..."
				l_FoundFlg=0
				for l_TmpStr in "${l_CurrMountAry[@]}"
				do
					DbgPrint "${FUNCNAME[0]}: Comparing current mount string \"$l_TmpStr\""
																# If branch mounted
					if [[ "$l_TmpStr" == "$l_BranchAbsPath" ]]; then
						DbgPrint "${FUNCNAME[0]}: Branch is currently mounted - \"$l_BranchAbsPath\""
						l_FoundFlg=1						# Set found flag
						break									# Break out of loop
					fi
				done

				if [ $l_FoundFlg -eq 1 ]; then		# If branch found
																# Add to unmount string
					DbgPrint "${FUNCNAME[0]}: Adding \"$l_BranchAbsPath\" to unmount string"
					if [ ! -z "$l_UmountStr" ]; then	# If previous entry
						l_UmountStr="${l_UmountStr}:"	# Add seperator
					fi
					l_UmountStr="${l_UmountStr}${l_BranchAbsPath}"
				else
					DbgPrint "${FUNCNAME[0]}: Branch not mounted - \"$l_BranchAbsPath\""
					MsgAdd $GC_MSGT_WARN "Branch \"$l_BranchAbsPath\" not mounted to \"$l_MergeAbsPath\"." "${!l_GlblVarAry}"
				fi
			fi
		done
																# If no error
		if [[ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ! -z "$l_UmountStr" ]]; then
																# Unmount branches
			DbgPrint "${FUNCNAME[0]}: Removing branches with 'xattr -w user.mergerfs.srcmounts \"-$l_UmountStr\" \"$l_MergeAbsPath/.mergerfs\"'"
			xattr -w user.mergerfs.srcmounts "-$l_UmountStr" "$l_MergeAbsPath/.mergerfs"
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*												Create Bottle										 *
#*******************************************************************************
#
# Function: Creates a new bottle. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Wine version.
#				Pathname		- Use specific wine.
#				""				- No specific wine version.
#	Arg3	Environment file name.
#				Pathname		- Use custom environment file.
#				"default"	- Create default environment.
#				""				- No environment.
#	Arg4  Optional submenu.
#	Arg5  Global Variable Array name.
#	Arg6	Strings Array name.
#	Arg7	XDG Directory Array name.
#	Arg8	XDG Desktop File Subpath Array name.
#
# Output:
#	Arg5	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleCreate ()
{
	local l_BottleName="$1"
	local l_WineDir="$2"
	local l_EnvFileName="$3"
	local l_Submenu="$4"
	local -n l_GlblVarAry="$5"
	local -n l_StrAry="$6"
	local -n l_XdgDirAry="$7"
	local -n l_XdgDsktpSubpathAry="$8"
	local l_RetStat=$WM_ERR_NONE
	local l_BottlePathname=""
	local l_WmBottleName=""
	local l_WmBottlePathname=""
	local l_ConfFile=""
	local l_TmpStr=""
	local l_BtlCopiedFlg=0

	DbgPrint "${FUNCNAME[0]}: Entered with Bottle name = \"$l_BottleName\", Wine version = \"$l_WineDir\", Environment file = \"$l_EnvFileName\", Submenu = \"$l_Submenu\"."
																# Bottle pathname
	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
	DbgPrint "${FUNCNAME[0]}: Bottle pathname = \"$l_BottlePathname\""
																# Bottle conf file
	l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
	DbgPrint "${FUNCNAME[0]}: Config file pathname = \"$l_ConfFile\""

	if [ -d "$l_BottlePathname" ]; then				# If bottle already exists
		ErrAdd $WM_ERR_BTL_EXISTS "${FUNCNAME[0]}${GC_SEP_FTRC}Bottle pathname = \"$l_BottlePathname\"" "${!l_GlblVarAry}"
	else
																# Create bottle from template
		cp -r "${l_StrAry[$E_STR_WM_BTL_TMPLT_DIR]}" "$l_BottlePathname" >/dev/null 2>&1
		l_RetStat=$?
		if [ $l_RetStat -ne $WM_ERR_NONE ];then	# If copy failes
			ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Bottle pathname = \"$l_BottlePathname\"" "${!l_GlblVarAry}"
		else
			l_BtlCopiedFlg=1								# Set bottle copied flag 

# Process Wine Directory
# ----------------------
			if [ ! -z "$l_WineDir" ]; then			# If wine dir not null
																# Strip any trailing slash from wine dir
				l_WineDir=`echo "$l_WineDir" | sed 's#/$##'`
				DbgPrint "${FUNCNAME[0]}: Strip complete, wine version = \"$l_WineDir\""
																
				if [ -z "$l_WineDir" ]; then			# If default exec
					l_TmpStr="wine"						# Exec is "wine"
				else
					l_TmpStr="$l_WineDir/bin/wine"	# Else create specific wine exec
				fi
				DbgPrint "New wine executable is \"$l_TmpStr\""
				which "$l_TmpStr" >/dev/null 2>&1	# Check if wine exec exists
				l_RetStat=$?
																# If it doesn't
				if [ $l_RetStat -ne $WM_ERR_NONE ];then
					ErrAdd $WM_ERR_FILE_NEXEC "${FUNCNAME[0]}${GC_SEP_FTRC}Wine Executable = \"$l_TmpStr\"" "${!l_GlblVarAry}"
				else

					DbgPrint "${FUNCNAME[0]}: Writing Key=\"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", Value=\"$l_WineDir\",Conf File=\"$l_ConfFile\""
																# Write wine dir to conf
					KeyWr "${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}" "$l_WineDir" "$l_ConfFile"
					l_RetStat=$?
					if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# If error set Standard Script error code
						ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", Value = \"$l_WineDir\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
					fi
				fi
			fi
		
# Process Environment File
# ------------------------
																# If no error
			if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
				BottleEnvCreate "$l_BottleName" "$l_EnvFileName" "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgDsktpSubpathAry}"
				l_RetStat=$?
				if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
					MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
				fi
			fi

# Process Submenu
# ---------------
																# If no error
			if [ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
																# Write submenu to conf
				KeyWr "${l_StrAry[$E_STR_KEY_BTL_SMENU]}" "$l_Submenu" "$l_ConfFile"
				l_RetStat=$?
				if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Set Standard Script error code
					ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_SMENU]}\", Value = \"$l_Submenu\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
				fi
			fi

# Add Wine Manager Menu Item
# --------------------------
			BottleWmMenuAdd "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"
		fi
	fi
	DbgPrint "${FUNCNAME[0]}: Final Status = \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\", l_BtlCopiedFlg = \"$l_BtlCopiedFlg\""
																# If error and bottle template was copied
	if [[ ${l_GlblVarAry[$E_GLBL_ERR_CODE]} -ne $WM_ERR_NONE && $l_BtlCopiedFlg -eq 1 ]]; then
		DbgPrint "${FUNCNAME[0]}: Trying to delete = \"$l_BottlePathname\""
																# Try to delete bottle
		rm -rf "$l_BottlePathname" >/dev/null 2>&1
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*								Wine Manager Bottle Base Menu Add							 *
#*******************************************************************************
#
# Function: Creates a Wine Manager menu base for bottle. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuAdd ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_TmpStr=""
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

	if BottleWmMenuAddBase "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"; then
		if BottleWmMenuAddConsole "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"; then
			BottleWmMenuAddXdgEnb "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*								Wine Manager Bottle Base Menu Add							 *
#*******************************************************************************
#
# Function: Creates a Wine Manager menu base for bottle. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuAddBase ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_TmpStr=""
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

																	# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Creating Wine Manager Install Menu item for bottle \"$l_BottleName\""

		l_WmBottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
		l_WmBottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_WmBottleName"
																	# Create bottle programs directory name
		l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}/${l_BottleName}"
		if [ ! -d "$l_TmpStr" ]; then					# If no bottle programs directory
			mkdir "$l_TmpStr" >/dev/null 2>&1			# Create it
		fi

		if [ ! -d "$l_TmpStr" ]; then					# If create failed
			ErrAdd $WM_ERR_DIR_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}Directory = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		else
																	# Create bottle .directory file
			l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.local/share/desktop-directories/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}.directory"
			cat > "$l_TmpStr" <<EOL
[Desktop Entry]
Type=Directory
Name=${l_BottleName}
Icon=folder
EOL
			if [ ! -f "$l_TmpStr" ]; then				# If create failed
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
			fi
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*							Wine Manager Bottle Console Menu Add							 *
#*******************************************************************************
#
# Function: Creates a Wine Manager menu for bottle. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuAddConsole ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_TmpStr=""
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Creating Wine Manager Console Menu item for bottle \"$l_BottleName\""

		l_WmBottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
		l_WmBottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_WmBottleName"
																# Create bottle .menu file
		l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.config/menus/applications-merged/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Console.menu"
		cat > "$l_TmpStr" <<EOL
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>wine-wine</Name>
    <Directory>wine-wine.directory</Directory>
  <Menu>
    <Name>wine-Programs</Name>
    <Directory>wine-Programs.directory</Directory>
  <Menu>
    <Name>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}</Name>
    <Directory>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}.directory</Directory>
  <Menu>
    <Name>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}</Name>
    <Directory>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}.directory</Directory>
    <Include>
      <Filename>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Console.desktop</Filename>
    </Include>
  </Menu>
  </Menu>
  </Menu>
  </Menu>
</Menu>
EOL
		if [ ! -f "$l_TmpStr" ]; then	# If create failed
			ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		else
																# Create bottle Console .desktop file
			l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}/${l_BottleName}/Console.desktop"
			cat > "$l_TmpStr" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Console
Comment=${l_BottleName} Launch Bottle Console
Icon=utilities-terminal
Exec=$ThisNameUser console -b ${l_BottleName}
NoDisplay=false
StartupNotify=false
Terminal=true
EOL
																# If create failed
			if [ ! -f "$l_TmpStr" ]; then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
			fi
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*							Wine Manager Bottle XDG Enable Menu Add						 *
#*******************************************************************************
#
# Function: Creates a Wine Manager XDG Enable menu for bottle. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuAddXdgEnb ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_TmpStr=""
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Creating Wine Manager XDG Enable Menu item for bottle \"$l_BottleName\""

		l_WmBottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
		l_WmBottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_WmBottleName"
																# Create bottle .menu file
		l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.config/menus/applications-merged/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Xdg.menu"
		cat > "$l_TmpStr" <<EOL
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>wine-wine</Name>
    <Directory>wine-wine.directory</Directory>
  <Menu>
    <Name>wine-Programs</Name>
    <Directory>wine-Programs.directory</Directory>
  <Menu>
    <Name>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}</Name>
    <Directory>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}.directory</Directory>
  <Menu>
    <Name>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}</Name>
    <Directory>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}.directory</Directory>
    <Include>
      <Filename>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Xdg.desktop</Filename>
    </Include>
  </Menu>
  </Menu>
  </Menu>
  </Menu>
</Menu>
EOL
		if [ ! -f "$l_TmpStr" ]; then	# If create failed
			ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		else
																# Create bottle XDG .desktop file
			l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}/${l_BottleName}/Xdg.desktop"
			cat > "$l_TmpStr" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Menu Enable
Comment=${l_BottleName} bottle menu enable
Icon=media-playback-start
Exec=$ThisNameUser xdg -op on -b ${l_BottleName}
NoDisplay=false
StartupNotify=false
Terminal=false
EOL
																# If create failed
			if [ ! -f "$l_TmpStr" ]; then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
			fi
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*							Wine Manager Bottle XDG Disable Menu Add						 *
#*******************************************************************************
#
# Function: Creates a Wine Manager XDG Disable menu for bottle. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuAddXdgDsb ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_TmpStr=""
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Creating Wine Manager XDG Disable Menu item for bottle \"$l_BottleName\""

		l_WmBottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
		l_WmBottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_WmBottleName"
																# Create bottle .menu file
		l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.config/menus/applications-merged/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Xdg.menu"
		cat > "$l_TmpStr" <<EOL
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>wine-wine</Name>
    <Directory>wine-wine.directory</Directory>
  <Menu>
    <Name>wine-Programs</Name>
    <Directory>wine-Programs.directory</Directory>
  <Menu>
    <Name>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}</Name>
    <Directory>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}.directory</Directory>
  <Menu>
    <Name>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}</Name>
    <Directory>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}.directory</Directory>
    <Include>
      <Filename>wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Xdg.desktop</Filename>
    </Include>
  </Menu>
  </Menu>
  </Menu>
  </Menu>
</Menu>
EOL
		if [ ! -f "$l_TmpStr" ]; then	# If create failed
			ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
		else
																# Create bottle XDG .desktop file
			l_TmpStr="${l_WmBottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}/${l_BottleName}/Xdg.desktop"
			cat > "$l_TmpStr" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Menu Disable
Comment=${l_BottleName} bottle menu disable
Icon=media-playback-pause
Exec=$ThisNameUser xdg -op off -b ${l_BottleName}
NoDisplay=false
StartupNotify=false
Terminal=false
EOL
																# If create failed
			if [ ! -f "$l_TmpStr" ]; then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_TmpStr\"" "${!l_GlblVarAry}"
			fi
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*												Bottle Delete										 *
#*******************************************************************************
#
# Function: Delete bottle.
#
# Input:
#	Arg1  Bottle Name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg4	XDG Directory Array name.
#	Arg5	XDG Subpath Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleDelete ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_EnvNameFile=""
	local l_EnvFile=""
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."
																# Bottle pathname
	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
	DbgPrint "${FUNCNAME[0]}: Bottle pathname \"$l_BottlePathname\""
																# Verify not active or default
	IsNotXdgDefaultSys "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"
	l_RetStat=$?
	if [ $l_RetStat -ne $WM_ERR_NONE ];then
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi
																# Unmount bottle
	BottleUnmount "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgSubpathAry}"
	l_RetStat=$?
	if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

	BottleWmMenuDel "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"

	DbgPrint "${FUNCNAME[0]}: Deleting bottle \"$l_BottlePathname\""
	rm -rf "$l_BottlePathname" >/dev/null 2>&1						# Delete bottle

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}


#*******************************************************************************
#*									Wine Manager Bottle Menu Delete							 *
#*******************************************************************************
#
# Function: Deletes a Wine Manager bottle menu entry. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuDel ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

	if BottleWmMenuDelXdg "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"; then
		if BottleWmMenuDelConsole "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"; then
			BottleWmMenuDelBase "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*								Wine Manager Bottle Base Menu Delete						 *
#*******************************************************************************
#
# Function: Deletes a Wine Manager bottle menu entry. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuDelBase ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Removing Wine Manager Menu .menu and .desktop files for bottle \"$l_BottleName\""
		l_WmBottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
		l_WmBottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_WmBottleName"
																# Delete bottle .directory file
		rm "${l_WmBottlePathname}/xdg/pri_bottle/.local/share/desktop-directories/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}.directory" >/dev/null 2>&1
																# Delete bottle programs directory
		rm -r "${l_WmBottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}/${l_BottleName}"  >/dev/null 2>&1
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*							Wine Manager Bottle Console Menu Delete						 *
#*******************************************************************************
#
# Function: Deletes a Wine Manager bottle Console menu entry. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuDelConsole ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Removing Wine Manager Menu Console .menu and .desktop files for bottle \"$l_BottleName\""
		l_WmBottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
		l_WmBottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_WmBottleName"
																# Delete bottle Console .menu file
		rm "${l_WmBottlePathname}/xdg/pri_bottle/.config/menus/applications-merged/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Console.menu" >/dev/null 2>&1
																# Delete bottle Console .desktop file
		rm "${l_WmBottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}/${l_BottleName}/Console.desktop" >/dev/null 2>&1
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*								Wine Manager Bottle XDG Menu Delete							 *
#*******************************************************************************
#
# Function: Deletes a Wine Manager XDG menu entry. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleWmMenuDelXdg ()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_WmBottleName=""
	local l_WmBottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

																# If not a system bottle
	if [ "${l_BottleName##*.}" != "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
		DbgPrint "${FUNCNAME[0]}: Removing Wine Manager XDG Menu .menu and .desktop files for bottle \"$l_BottleName\""
		l_WmBottleName="${l_StrAry[$E_STR_WM_SYS_BTL_NAME]}"
		l_WmBottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_WmBottleName"
																# Delete bottle XDG .menu file
		rm "${l_WmBottlePathname}/xdg/pri_bottle/.config/menus/applications-merged/wine-Programs-${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}-${l_BottleName}-Xdg.menu" >/dev/null 2>&1
																# Delete bottle XDG .desktop file
		rm "${l_WmBottlePathname}/xdg/pri_bottle/.local/share/applications/wine/Programs/${l_StrAry[$E_STR_WM_SYS_MENU_NAME]}/${l_BottleName}/Xdg.desktop" >/dev/null 2>&1
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Create Bottle Environment								 *
#*******************************************************************************
#
# Function: Creates or recreates bottle environment by writing or deleting
#				environment file and updating bottle desktop files. 
#
# Input:
#	Arg1  Bottle name.
#	Arg2  Environment copy file.
#				Pathname		- Use custom environment file
#				"default"	- Create default environment.
#				""				- No environment.
#	Arg3  Global Variable Array name.
#	Arg4	Strings Array name.
#	Arg5	XDG Directory Array name.
#	Arg6	XDG Desktop File Subpath Array name.
#
# Output: No variables passed.
#
function BottleEnvCreate ()
{
	local l_BottleName="$1"
	local l_EnvCopyFile="$2"
	local -n l_GlblVarAry="$3"
	local -n l_StrAry="$4"
	local -n l_XdgDirAry="$5"
	local -n l_XdgDsktpSubpathAry="$6"
	local l_RetStat=$WM_ERR_NONE
	local l_BottlePathname=""
	local l_ConfFile=""
	local l_EnvFileName=""
	local l_WineDir=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\", Environment copy file \"$l_EnvCopyFile\"."

																# Bottle pathname
	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
																# Bottle conf file
	l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
																# Env file pathname
	l_EnvFilePathname="$l_BottlePathname/${l_StrAry[$E_STR_BTL_BIN_DIR]}/${l_StrAry[$E_STR_BTL_ENV_FILE_NAME]}"

	DbgPrint "${FUNCNAME[0]}: Environment file name is \"$l_EnvFilePathname\"."
	if [ ! -z "$l_EnvCopyFile" ]; then				# If not deleting environment
		if [ "$l_EnvCopyFile" != "default" ]; then	# If copying file
			DbgPrint "${FUNCNAME[0]}: Copying new environment file \"$l_EnvCopyFile\" to \"$l_EnvFilePathname\"."
			if [ ! -f "$l_EnvCopyFile" ]; then		# If copy file doesn't exist
				ErrAdd $WM_ERR_FILE_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_EnvCopyFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
																# Copy env file
			cp "$l_EnvCopyFile" "$l_EnvFilePathname" >/dev/null 2>&1;
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_EnvFilePathname\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		else													# If create default environment
																# Get bottle wine version
			KeyRd "${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}" "l_WineDir" "$l_ConfFile"
			l_RetStat=$?
			if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
				ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi

# !!!! NEED to take this from .profile. Just strip profile WINEMGR_DWINE_PATH. This is because lib/lib32/lib64 change depending upon how wine is compiled. !!!

																# Create default env file
			cat > "$l_EnvFilePathname" <<EOL
#!/bin/bash
export WINEMGR_DWINE_PATH=$l_WineDir
export PATH=\$WINEMGR_DWINE_PATH/bin:\$PATH 
export WINESERVER=\$WINEMGR_DWINE_PATH/bin/wineserver
export WINELOADER=\$WINEMGR_DWINE_PATH/bin/wine
export WINEDLLPATH=\$WINEMGR_DWINE_PATH/lib/wine/fakedlls:\$WINEMGR_DWINE_PATH/lib32/wine/fakedlls
export LD_LIBRARY_PATH="\$WINEMGR_DWINE_PATH/lib:\$WINEMGR_DWINE_PATH/lib32:\$LD_LIBRARY_PATH"

# Set Wine Realtime Priority
export STAGING_RT_PRIORITY_SERVER=95
export STAGING_RT_PRIORITY_BASE=95
EOL
			if [ ! -f "$l_EnvFilePathname" ]; then	# If create failed
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_EnvFilePathname\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		fi
																# Write bottle XDG Environment
		echo -e "\n# START - Wine Manager automically insterted environment ! DO NOT DELETE !" >> "$l_EnvFilePathname"
		echo "export XDG_DESKTOP_DIR=\"$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_TO_BOTTLE]}/Desktop\"" >> "$l_EnvFilePathname"
		echo "export XDG_CONFIG_HOME=\"$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_TO_BOTTLE]}/.config\"" >> "$l_EnvFilePathname"
		echo "export XDG_DATA_HOME=\"$l_BottlePathname/${l_XdgDirAry[$E_XDG_BOTTLE_TO_BOTTLE]}/.local/share\"" >> "$l_EnvFilePathname"
		echo "# END - Wine Manager automically insterted environment" >> "$l_EnvFilePathname"
		chmod a+x "$l_EnvFilePathname"				# Make it executable
																# Insert env in desktop files
		DbgPrint "${FUNCNAME[0]}: Inserting environment \"$l_EnvFilePathname\" into bottle \"$l_BottlePathname\"."
		BottleEnvInsert "$l_BottlePathname" "$l_EnvFilePathname" "${!l_XdgDirAry}" "${!l_XdgDsktpSubpathAry}"
	else														# If deleting environment
		DbgPrint "${FUNCNAME[0]}: Deleting environment for \"$l_BottlePathname\"."
		BottleEnvDelete "$l_BottlePathname" "${!l_XdgDirAry}" "${!l_XdgDsktpSubpathAry}"
		if [ -f "$l_EnvFilePathname" ]; then		# If existing env file
			DbgPrint "${FUNCNAME[0]}: Deleting environment file \"$l_EnvFilePathname\"."
			rm "$l_EnvFilePathname" >/dev/null 2>&1;		# Remove environment file
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_DEL "${FUNCNAME[0]}${GC_SEP_FTRC}File = \"$l_EnvFilePathname\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		fi
		l_EnvFilePathname=""								# Set env to none
	fi
																# Write env script pathname to key
	KeyWr "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "$l_EnvFilePathname" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Build Translate XDG									 *
#*******************************************************************************
#
# Function: Builds translated bottle XDG
#
# Input:
#	Arg1	Full bottle pathname
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#	Arg4	XDG Directory Array name.
#	Arg5	XDG Subpath Array name.
#	Arg6	XDG Desktop File Subpath Array name.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BuildTranslateXDG()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgSubpathAry="$5"
	local -n l_XdgDsktpSubpathAry="$6"
	local l_RetStat=$WM_ERR_NONE
	local l_BottlePathname=""
	local l_ConfFile=""
	local l_BottleXdgRoot=""
	local l_TranslateXdgRoot=""
	local l_SubMenuFile=""
	local l_MenuFileIn=""
	local l_TmpMainMenuFile=""
	local l_MenuTarg
	local l_MenuAdd
	local l_TmpFile=""
	local l_MainDirFile=""
	local l_TmpDir=""
	local l_MenuTargBase=""
	local l_XdgDirFile=""
	local l_SubMenuFrag=""
	local l_SubMenuRaw=""
	local l_SubMenu=""
	local l_SubMenuPath=""
	local l_OldIFS=""
	local l_TmpIdx=0

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\""
																# Bottle pathname
	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
	DbgPrint "${FUNCNAME[0]}: Bottle pathname = \"$l_BottlePathname\""
																# Verify bottle exists
	BottleExists "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"
	l_RetStat=$?
	if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi
																# Bottle conf file
	l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
	DbgPrint "${FUNCNAME[0]}: Conf file pathname = \"$l_ConfFile\""
																# Get Private Bottle XDG root
	l_BottleXdgRoot="$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}"
	DbgPrint "${FUNCNAME[0]}: l_BottleXdgRoot=$l_BottleXdgRoot"
																# Get Private Bottle Translate XDG root
	l_TranslateXdgRoot="$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE_TRANS]}"
	DbgPrint "${FUNCNAME[0]}: l_TranslateXdgRoot=$l_TranslateXdgRoot"
																# Get submenu
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_SMENU]}" "l_SubMenuRaw" "$l_ConfFile"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_SMENU]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
	DbgPrint "${FUNCNAME[0]}: Raw submenu = \"$l_SubMenuRaw\""

	DbgPrint "${FUNCNAME[0]}: Inserting environment in all \".desktop\" files for bottle \"$l_BottlePathname\""
																# Insert environment in all bottle desktop files
	BottleEnvInsertStandard "$l_BottlePathname" "${!l_GlblVarAry}" "${!l_StrAry}" "${!l_XdgDirAry}" "${!l_XdgDsktpSubpathAry}"
	l_RetStat=$?
	if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

	DbgPrint "${FUNCNAME[0]}: Deleting all Private Bottle Translate XDG data in \"$l_TranslateXdgRoot\""
																# Delete current translate XDG
	DeleteXdgData "$l_TranslateXdgRoot" "${!l_GlblVarAry}" "${!l_XdgSubpathAry}"
	l_RetStat=$?
	if [ $l_RetStat -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
		MsgPrepend "${FUNCNAME[0]}${GC_SEP_FTRC}" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi
																# Copy bottle XDG to translate XDG
	DbgPrint "${FUNCNAME[0]}: Copying common Private Bottle XDG data in \"$l_BottleXdgRoot\" to Bottle Translate XDG \"$l_TranslateXdgRoot\""
	rsync -aAXq --exclude={"/Desktop/*.url","/Desktop/*.lnk","/.config/menus/applications-merged/*.menu","/.local/share/applications/wine/Programs/*","/.local/share/desktop-directories/wine-Programs*.directory"} "$l_BottleXdgRoot/" "$l_TranslateXdgRoot" 2>&1 >/dev/null
	l_RetStat=$?
	if [ $l_RetStat -ne $WM_ERR_NONE ];then
		ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}rsync Status = \"$l_RetStat\", Source = \"$l_BottleXdgRoot/\", Destination = \"$l_TranslateXdgRoot\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi

# ~~~~~~~~~~~~~~
# Build Sub Menu
# ~~~~~~~~~~~~~~
	if [ ! -z "$l_SubMenuRaw" ]; then				# If we have a sub menu
		DbgPrint "${FUNCNAME[0]}: Sub menu detected, creating Translate XDG for bottle \"$l_BottlePathname\""
		l_SubMenu=`echo "$l_SubMenuRaw" | tr ":" "-"`
		l_SubMenuPath=`echo "$l_SubMenuRaw" | tr ":" "/"`
		local -a l_SubMenuAry
		l_OldIFS="$IFS"
		IFS=":"
		l_SubMenuAry=( $l_SubMenuRaw )
		IFS="$l_OldIFS"

		DbgPrint "${FUNCNAME[0]}: Sub Menu \"$l_SubMenu\""
		DbgPrint "${FUNCNAME[0]}: Sub Menu Path \"$l_SubMenuPath\""

# Modify .config/menus/applications-merged/*.menu files
# -----------------------------------------------------
		DbgPrint "${FUNCNAME[0]}: Modifying .menu files for bottle \"$l_BottlePathname\""
		l_TmpDir="$l_BottleXdgRoot/.config/menus/applications-merged"
		cd "$l_TmpDir"										# Get all .menu files
		find . -print | grep -i '.menu' | while read l_MenuFileIn; do
			DbgPrint "${FUNCNAME[0]}: Modifying file \"$l_MenuFileIn\"."
			l_TmpFile="${l_MenuFileIn#./}"			# Remove leading ./
																# Create new file name
			l_TmpMainMenuFile=$(sed "s/wine-Programs-/&$l_SubMenu-/" <<< "$l_TmpFile")
			l_TmpFile="$l_TranslateXdgRoot/.config/menus/applications-merged/$l_TmpMainMenuFile.tmp"
																# Copy menu file to temp file
			cp "$l_MenuFileIn" "$l_TmpFile"  >/dev/null 2>&1
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}cp Status = \"$l_RetStat\", Source = \"$l_MenuFileIn/\", Destination = \"$l_TmpFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
																# Change "wine-Programs-xxx" strings
			sed -i "s#wine-Programs-#&$l_SubMenu-#" "$l_TmpFile"  >/dev/null 2>&1
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}sed failed changing \"wine-Programs-xxx\" strings, Status = \"$l_RetStat\", File = \"$l_TmpFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi

			l_MenuTargBase="wine-Programs"			# Set first find target base
																# Build for each dir fragment
			for l_SubMenuFrag in "${l_SubMenuAry[@]}"
			do
																# Set find target
				l_MenuTarg="$l_MenuTargBase.directory"
				DbgPrint "${FUNCNAME[0]}: Menu search target \"$l_MenuTarg\"."
				l_MenuAdd="$l_MenuTargBase-$l_SubMenuFrag"
				DbgPrint "${FUNCNAME[0]}: Adding menu entry for \"$l_MenuAdd\"."
																# Add new sub menu entry
				sed -i "/<Directory>$l_MenuTarg<\/Directory>/a\  <Menu>\n	 <Name>$l_MenuAdd<\/Name>\n	 <Directory>$l_MenuAdd.directory<\/Directory>" "$l_TmpFile"  >/dev/null 2>&1
				l_RetStat=$?
				if [ $l_RetStat -ne $WM_ERR_NONE ];then
					ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}sed failed adding new submenu entry, Status = \"$l_RetStat\", File = \"$l_TmpFile\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
																# Add </Menu> tag
				sed -i -e '/<\/Menu>/{i\  <\/Menu>' -e ':a;$q;n;ba;}' "$l_TmpFile"  >/dev/null 2>&1
				l_RetStat=$?
				if [ $l_RetStat -ne $WM_ERR_NONE ];then
					ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}sed failed adding </Menu> tag, Status = \"$l_RetStat\", File = \"$l_TmpFile\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi

				l_MenuTargBase="$l_MenuTargBase-$l_SubMenuFrag"
			done
																# Move to main file
			mv "$l_TmpFile" "$l_TranslateXdgRoot/.config/menus/applications-merged/$l_TmpMainMenuFile"
		done

# Copy .local/share/applications/wine/Programs files to new subdirectory
# ----------------------------------------------------------------------
																# If directory not empty
		if [ "$(ls -A "$l_BottleXdgRoot/.local/share/applications/wine/Programs")" ]; then
			l_TmpDir="$l_TranslateXdgRoot/.local/share/applications/wine/Programs/$l_SubMenuPath"
			DbgPrint "${FUNCNAME[0]}: Copying Private Bottle XDG \"$l_BottleXdgRoot/.local/share/applications/wine/Programs\" to Bottle Translate XDG \"$l_TmpDir\""
			mkdir -p "$l_TmpDir"
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_DIR_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}mkdir Status = \"$l_RetStat\", Directory = \"$l_TmpFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi

			cp -r "$l_BottleXdgRoot/.local/share/applications/wine/Programs"/* "$l_TmpDir" >/dev/null 2>&1
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}cp -r Status = \"$l_RetStat\", Source = \"$l_BottleXdgRoot/.local/share/applications/wine/Programs/*\", Destination = \"$l_TmpFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		fi

# Modify and copy .local/share/desktop-directories .directory files
# -----------------------------------------------------------------
		DbgPrint "${FUNCNAME[0]}: Modifying and copying Private Bottle Translate XDG \"$l_TranslateXdgRoot/.local/share/desktop-directories\" files"
																# Create sub menu directory file
		l_TmpDir="$l_TranslateXdgRoot/.local/share/desktop-directories"
		l_MenuTargBase="wine-Programs"				# Set first find target base
																# Build for each dir fragment
		for l_SubMenuFrag in "${l_SubMenuAry[@]}"
		do

			l_TmpFile="$l_TmpDir/$l_MenuTargBase-$l_SubMenuFrag.directory"
			if [ ! -e "$l_TmpFile" ]; then			# If file doesn't exist
																# Create it
				DbgPrint "${FUNCNAME[0]}: Creating \"$l_TmpFile\" for bottle \"$l_BottlePathname\""
				cat > "$l_TmpFile" <<EOL
[Desktop Entry]
Type=Directory
Name=$l_SubMenuFrag
Icon=folder
EOL
				l_RetStat=$?
				if [ $l_RetStat -ne $WM_ERR_NONE ];then
					ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}cat Status = \"$l_RetStat\", File = \"$l_TmpFile\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			fi
			l_MenuTargBase="$l_MenuTargBase-$l_SubMenuFrag"
		done
																# Modify directory files
		l_TmpDir="$l_BottleXdgRoot/.local/share/desktop-directories"
		cd "$l_TmpDir"									# Get all .menu files
		find . -print | grep -i '.directory' | while read l_XdgDirFile; do
			l_TmpFile="${l_XdgDirFile#./}"			# Remove leading ./
			DbgPrint "${FUNCNAME[0]}: Modifying file \"$l_TmpFile\""
																# Create new file name
			l_MainDirFile=$(sed "s/wine-Programs-/&$l_SubMenu-/" <<< "$l_TmpFile")
																# Copy dir file to temp file
			DbgPrint "${FUNCNAME[0]}: Copying modified file \"$l_XdgDirFile\" to \"$l_TranslateXdgRoot/.local/share/desktop-directories/$l_MainDirFile\""
			cp "$l_XdgDirFile" "$l_TranslateXdgRoot/.local/share/desktop-directories/$l_MainDirFile" >/dev/null 2>&1
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}cp Status = \"$l_RetStat\", Source = \"$l_XdgDirFile\", Destination = \"$l_TranslateXdgRoot/.local/share/desktop-directories/$l_MainDirFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		done
	else														# If no submenu
		DbgPrint "${FUNCNAME[0]}: No sub menu detected, doing direct copy to translate XDG for bottle \"$l_BottlePathname\""

		if [ "$(ls -A "$l_BottleXdgRoot/.config/menus/applications-merged"/*.menu)" ]; then
#		if [ -f "$l_BottleXdgRoot/.config/menus/applications-merged"/*.menu ]; then

			cp -r "$l_BottleXdgRoot/.config/menus/applications-merged"/*.menu "$l_TranslateXdgRoot/.config/menus/applications-merged" >/dev/null 2>&1
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}cp -r Status = \"$l_RetStat\", Source = \"$l_BottleXdgRoot/.config/menus/applications-merged/*.menu\", Destination = \"$l_TranslateXdgRoot/.config/menus/applications-merged\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		fi
		
		if [ -e "$l_BottleXdgRoot/.local/share/applications/wine/Programs"/* ]; then
			cp -r "$l_BottleXdgRoot/.local/share/applications/wine/Programs"/* "$l_TranslateXdgRoot/.local/share/applications/wine/Programs" >/dev/null 2>&1
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}cp -r Status = \"$l_RetStat\", Source = \"$l_BottleXdgRoot/.local/share/applications/wine/Programs/*\", Destination = \"$l_TranslateXdgRoot/.local/share/applications/wine/Programs\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		fi

		if [ "$(ls -A "$l_BottleXdgRoot/.local/share/desktop-directories"/*.directory)" ]; then
#		if [ -f "$l_BottleXdgRoot/.local/share/desktop-directories"/*.directory ]; then
			cp -r "$l_BottleXdgRoot/.local/share/desktop-directories"/*.directory "$l_TranslateXdgRoot/.local/share/desktop-directories" >/dev/null 2>&1
			l_RetStat=$?
			if [ $l_RetStat -ne $WM_ERR_NONE ];then
				ErrAdd $WM_ERR_FILE_CREATE "${FUNCNAME[0]}${GC_SEP_FTRC}cp -r Status = \"$l_RetStat\", Source = \"$l_BottleXdgRoot/.local/share/desktop-directories/wine-Programs*.directory\", Destination = \"$l_TranslateXdgRoot/.local/share/desktop-directories\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*									Custom XDG Refresh Function								 *
#*******************************************************************************
#
# Function: Executes custom XDG refresh command, if any.
#
# Input:
#	Arg1	Optional refresh command.
#	Arg2	Global Variable Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function CustomXdgRefresh ()
{
	local l_RefreshCmd="$1"
	local -n l_GlblVarAry="$2"
	local l_TmpStat=0

	DbgPrint "${FUNCNAME[0]}: Entered with refresh command = \"$l_RefreshCmd\""
																# If XDG refresh command
	if [[ ! -z "${l_RefreshCmd// }" ]]; then
		 DbgPrint "Executing custom XDG refresh command: \"$l_RefreshCmd\"."
		`$l_RefreshCmd`
		l_TmpStat=$?
		if [ ! $l_TmpStat ]; then
			ErrAdd $WM_ERR_RFRSH_XDG "${FUNCNAME[0]}${GC_SEP_FTRC}Command = \"$l_RefreshCmd\", Status = \"$l_TmpStat\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	fi
	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*											Verify Bottle Exists									 *
#*******************************************************************************
#
# Function: Verifies bottle exists.
#
# Input:
#	Arg1	 Bottle Name.
#	Arg2	 Global Variable Array name.
#	Arg3	 Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleExists()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

	if [ -z "$l_BottleName" ]; then					# If null bottle name
		ErrAdd $WM_ERR_BTL_NNAME "" "${!l_GlblVarAry}"
	else
																# Bottle pathname
		l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
		DbgPrint "${FUNCNAME[0]}: Bottle pathname = \"$l_BottlePathname\"."

		if [ ! -d $l_BottlePathname ]; then			# If it doesn't exist
			ErrAdd $WM_ERR_BTL_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Bottle pathname = \"$l_BottlePathname\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status = \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Verify Backup Bottle Exists							 *
#*******************************************************************************
#
# Function: Verifies backup bottle exists.
#
# Input:
#	Arg1	 Bottle Name.
#	Arg2	 Global Variable Array name.
#	Arg3	 Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BackupBottleExists()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."

	if [ -z "$l_BottleName" ]; then					# If null bottle name
		ErrAdd $WM_ERR_BTL_NNAME "" "${!l_GlblVarAry}"
	else
																# Bottle pathname
		l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_BCKP_DIR]}/$l_BottleName"
		DbgPrint "${FUNCNAME[0]}: Bottle pathname = \"$l_BottlePathname\"."

		if [ ! -d $l_BottlePathname ]; then			# If it doesn't exist
			ErrAdd $WM_ERR_BTL_NEXIST "${FUNCNAME[0]}${GC_SEP_FTRC}Backup bottle pathname = \"$l_BottlePathname\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status = \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*								Check if Wine Manager Initialized							 *
#*******************************************************************************
#
# Function: Verifies Wine Manager is initialized.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2	Strings Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function IsInit()
{
	local -n l_GlblVarAry="$1"
	local -n l_StrAry="$2"
	local l_RetStat=0
	local l_InitVal=0

	DbgPrint "${FUNCNAME[0]}: Entered"
															# Get initialized key value
	KeyRd "${l_StrAry[$E_STR_KEY_WM_INIT]}" l_InitVal "${l_StrAry[$E_STR_WM_CONF_FILE]}"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ]; then
															# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_WM_INIT]}\", File = \"${l_StrAry[$E_STR_WM_CONF_FILE]}\"" "${!l_GlblVarAry}"

	elif [ $l_InitVal -eq 0 ]; then				# If Wine Manager not initialized
															# Exit with error
		ErrAdd $WM_ERR_INIT "" G_GLBL_VAR_ARY
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status = \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}
	

#*******************************************************************************
#*								Check if Wine Manager Deinitialized							 *
#*******************************************************************************
#
# Function: Verifies Wine Manager is deinitialized.
#
# Input:
#	Arg1  Global Variable Array name.
#	Arg2	Strings Array name.
#
# Output:
#	Arg1	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function IsDeinit()
{
	local -n l_GlblVarAry="$1"
	local -n l_StrAry="$2"
	local l_RetStat=0
	local l_InitVal=0

	DbgPrint "${FUNCNAME[0]}: Entered"
															# Get initialized key value
	KeyRd "${l_StrAry[$E_STR_KEY_WM_INIT]}" l_InitVal "${l_StrAry[$E_STR_WM_CONF_FILE]}"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ]; then
															# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_WM_INIT]}\", File = \"${l_StrAry[$E_STR_WM_CONF_FILE]}\"" "${!l_GlblVarAry}"

	elif [ $l_InitVal -eq 1 ]; then				# If Wine Manager not deinitialized
															# Exit with error
		ErrAdd $WM_ERR_DEINIT "" G_GLBL_VAR_ARY
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status = \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}
	

#*******************************************************************************
#*						Is Initialized/Command Arguments Result Check					 *
#*******************************************************************************
#
# Function: Verifies Wine Manager is initialized and verifies arguments.
#
# Input:
#	Arg1  TokParse_TokChk exit status
#	Arg2  TokParse_TokChk invalid token
#	Arg3	Global Variable Array name.
#	Arg4	Strings Array name.
#
# Output:
#	Arg3 E_GLBL_ERR_CODE contains offset Token Parser error status if error,
#
# Exit Status:
#	Returns offset error status if error, otherwise unchanged status.
#
function IsInitArgsRsltChk ()
{
	local l_TcExitStat="$1"
	local l_InvTok="$2"
	local -n l_GlblVarAry="$3"
	local -n l_StrAry="$4"

	DbgPrint "${FUNCNAME[0]}: Entered"
																# If initialized
	if IsInit "${!l_GlblVarAry}" "${!l_StrAry}"; then
																# Check arguments
		ArgsRsltChk "$l_TcExitStat" "$l_InvTok" "${!l_GlblVarAry}"
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status = \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*						Is Deinitialized/Command Arguments Result Check					 *
#*******************************************************************************
#
# Function: Verifies Wine Manager is deinitialized and verifies arguments.
#
# Input:
#	Arg1  TokParse_TokChk exit status
#	Arg2  TokParse_TokChk invalid token
#	Arg3	Global Variable Array name.
#	Arg4	Strings Array name.
#
# Output:
#	Arg3 E_GLBL_ERR_CODE contains offset Token Parser error status if error,
#
# Exit Status:
#	Returns offset error status if error, otherwise unchanged status.
#
function IsDeinitArgsRsltChk ()
{
	local l_TcExitStat="$1"
	local l_InvTok="$2"
	local -n l_GlblVarAry="$3"
	local -n l_StrAry="$4"

	DbgPrint "${FUNCNAME[0]}: Entered"
																# If deinitialized
	if IsDeinit "${!l_GlblVarAry}" "${!l_StrAry}"; then
																# Check arguments 
		ArgsRsltChk "$l_TcExitStat" "$l_InvTok" "${!l_GlblVarAry}"
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status = \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}
#*******************************************************************************
#*									Command Arguments Result Check							 *
#*******************************************************************************
#
# Function: Gets usage message for command.
#
# Input:
#	Arg1  TokParse_TokChk exit status
#	Arg2  TokParse_TokChk invalid token
#	Arg3	Global Variable Array name.
#
# Output:
#	Arg3 E_GLBL_ERR_CODE contains offset Token Parser error status if error,
#
# Exit Status:
#	Returns offset error status if error, otherwise unchanged status.
#
function ArgsRsltChk ()
{
	local l_TcExitStat="$1"
	local l_InvTok="$2"
	local -n l_GlblVarAry="$3"

	DbgPrint "${FUNCNAME[0]}: Entered"

	if [ $l_TcExitStat -ne $TP_ERR_NONE ]; then	# If error
																# Add offset for Token Parser error code
		ErrAdd $(($WM_ERR_TOTAL+$GC_KF_ERR_TOTAL+$l_TcExitStat)) "Token \"$l_InvTok\"" "${!l_GlblVarAry}"
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}


#*******************************************************************************
#*						  		System Configuration Variable Check							 *
#*******************************************************************************
#
# Function: Checks to see if a variable is in a system configuration array.
#
# Input:
#	Arg1	Configuration variable name.
#	Arg2	Protected configuration variable array name.
#	Arg3	Writeable configuration variable array name.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	GC_FUNCS_VarTypeChk_P	Protected configuration variable.
#	GC_FUNCS_VarTypeChk_W	Writable configuration variable.
#	GC_FUNCS_VarTypeChk_U	User configuration variable.
#
function VarTypeChk()
{
	local l_VarNameIn="$1"
	local -n __VTC_l_ConfVarPAry="$2"
	local -n __VTC_l_ConfVarWAry="$3"
	local l_i=0
	local l_iMax=0
	local l_VarName=""
	local l_ExitStat=$GC_FUNCS_VarTypeChk_U		# Default is user variable
	
	DbgPrint "${FUNCNAME[0]}: Entered with Variable Name = \"$l_VarNameIn\", Protected conf var array name = \"${!__VTC_l_ConfVarPAry}\", Writable conf var array name = \"${!__VTC_l_ConfVarWAry}\""

	l_iMax=${#__VTC_l_ConfVarPAry[@]}				# Get number of protected vars
	DbgPrint "${FUNCNAME[0]}: Number of protected variables = \"$l_iMax\""

	for ((l_i=0; l_i < l_iMax; l_i++));
	do
																# Get protected var name
		l_VarName="${!__VTC_l_ConfVarPAry[l_i]:0:1}"
		DbgPrint "${FUNCNAME[0]}: Variable Name = \"$l_VarName\""
																# If var name found
		if [ "$l_VarNameIn" == "$l_VarName" ]; then
			DbgPrint "${FUNCNAME[0]}: Variable name found = \"$l_VarNameIn\""
			l_ExitStat=$GC_FUNCS_VarTypeChk_P		# Set protected variable status
			break												# Exit loop
		fi
	done
																# If not protected var
	if [ $l_ExitStat -eq $GC_FUNCS_VarTypeChk_U ]; then
		l_iMax=${#__VTC_l_ConfVarWAry[@]}			# Get number of writable vars
		DbgPrint "${FUNCNAME[0]}: Number of writeable variables = \"$l_iMax\""

		for ((l_i=0; l_i < l_iMax; l_i++));
		do
			l_VarName="${!__VTC_l_ConfVarWAry[l_i]:0:1}"	# Get writable var name
			DbgPrint "${FUNCNAME[0]}: Variable Name = \"$l_VarName\""
																# If var name found
			if [ "$l_VarNameIn" == "$l_VarName" ]; then
				DbgPrint "${FUNCNAME[0]}: Variable name found = \"$l_VarNameIn\""
				l_ExitStat=$GC_FUNCS_VarTypeChk_W	# Set writable variable status
				break											# Exit loop
			fi
		done
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"$l_ExitStat\"."
	return $l_ExitStat
}

#*******************************************************************************
#*					Configuration Variable Existence and Value Check					 *
#*******************************************************************************
#
# Function: Verifies a configuration variable exists and the value is allowed.
#
# Input:
#	Arg1	Configuration variable name.
#	Arg2	Configuration variable value.
#	Arg3	Protected configuration variable array name.
#	Arg4	Writeable configuration variable array name.
#	Arg5	Variable type code return variable name.
#	Arg6	Global Variable Array name.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function VarValChk()
{
	local l_VarNameIn="$1"
	local l_VarValIn="$2"
	local -n __VVC_l_ConfVarPAry="$3"
	local -n __VVC_l_ConfVarWAry="$4"
	local -n __VVC_l_VarTypeOut="$5"
	local -n l_GlblVarAry="$6"
	local l_i=0
	local l_iMax=0
	local l_VarName=""
	local l_VarDesc=""
	local l_VarVal=""
	local l_FoundFlg=0
	
	DbgPrint "${FUNCNAME[0]}: Entered with Variable Name = \"$l_VarNameIn\", Protected conf var array name = \"${!__VVC_l_ConfVarPAry}\", Writable conf var array name = \"${!__VVC_l_ConfVarWAry}\""
																
																# Get variable type
	VarTypeChk "$l_VarNameIn" "${!__VVC_l_ConfVarPAry}" "${!__VVC_l_ConfVarWAry}"
	__VVC_l_VarTypeOut=$?
	DbgPrint "${FUNCNAME[0]}: Configurtion Variable Type for \"$l_VarNameIn\" = \"$__VVC_l_VarTypeOut\""
																# Check value if not user variable
	if [ $__VVC_l_VarTypeOut -ne $GC_FUNCS_VarTypeChk_U ]; then
																# If protected variable
		if [ $__VVC_l_VarTypeOut -eq $GC_FUNCS_VarTypeChk_P ]; then
			DbgPrint "${FUNCNAME[0]}: Loading protected variable protected value array name \"${!__VVC_l_ConfVarPAry}\""
																# Check protected array vars
			local -n l_ConfVarAry="${!__VVC_l_ConfVarPAry}"
		else													# If writeable variable
			DbgPrint "${FUNCNAME[0]}: Loading protected variable protected value array name \"${!__VVC_l_ConfVarWAry}\""
																# Check writeable array vars
			local -n l_ConfVarAry="${!__VVC_l_ConfVarWAry}"
		fi
		DbgPrint "${FUNCNAME[0]}: Loaded variable value array name = \"${!l_ConfVarAry}\""


		l_iMax=${#l_ConfVarAry[@]}						# Get number of variables
		DbgPrint "${FUNCNAME[0]}: Number of variables = \"$l_iMax\""
		for ((l_i=0; l_i < l_iMax; l_i++));
		do
			l_VarName="${!l_ConfVarAry[l_i]:0:1}"	# Get variable name
			DbgPrint "${FUNCNAME[0]}: Variable Name = \"$l_VarName\""
																# Get variable value array
			local -n l_VarValChkAry="${!l_ConfVarAry[l_i]:1:1}"
			DbgPrint "${FUNCNAME[0]}: Variable Value Array Name = \"${!l_ConfVarAry}\""

			l_VarDesc="${!l_ConfVarAry[l_i]:2:1}"	# Get variable description
			DbgPrint "${FUNCNAME[0]}: Variable Description = \"$l_VarDesc\""
																# If variable name found
			if [ "$l_VarNameIn" == "$l_VarName" ]; then
				DbgPrint "${FUNCNAME[0]}: Variable name found = \"$l_VarNameIn\""
				break
			fi
		done

		DbgPrint "${FUNCNAME[0]}: Variable \"$l_VarNameIn\" variable check array name is \"${!l_VarValChkAry}\""

		l_iMax=${#l_VarValChkAry[@]}					# Get number of valid variable values
		DbgPrint "${FUNCNAME[0]}: Number of variable values = \"$l_iMax\""
		l_FoundFlg=0
		for ((l_i=0; l_i < l_iMax; l_i++));
		do
			l_VarVal="${l_VarValChkAry[l_i]}"		# Get valid variable value
			DbgPrint "${FUNCNAME[0]}: Variable check value = \"$l_VarVal\""
																# If input value found or wildcard value
			if [[ "$l_VarValIn" == "$l_VarVal" || "$l_VarVal" == '*' ]]; then
				DbgPrint "${FUNCNAME[0]}: Valid variable value found, Input = \"$l_VarValIn\", Match = \"$l_VarVal\""
				l_FoundFlg=1								# Set found flag
				break
			fi
		done

		if [ $l_FoundFlg -eq 0 ]; then				# If value not found
			ErrAdd $WM_ERR_CVAR_INVVAL "${FUNCNAME[0]}${GC_SEP_FTRC}Variable Name = \"$l_VarNameIn\", Description = \"$l_VarDesc\", Variable Value = \"$l_VarValIn\"" "${!l_GlblVarAry}"
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Verify Not System Bottle								 *
#*******************************************************************************
#
# Function: Verifies bottle is not a system bottle.
#
# Input:
#	Arg1	 Bottle Name.
#	Arg2	 Global Variable Array name.
#	Arg3	 Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function IsNotSys()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
																# If system bottle
	if [ "${l_BottleName##*.}" == "${l_StrAry[$E_STR_WM_SYS_EXT]}" ]; then
																# Return error code
		ErrAdd $WM_ERR_BTL_SYS "" "${!l_GlblVarAry}"
	fi	

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*						  Verify Bottle Host XDG Not On And Not Default					 *
#*******************************************************************************
#
# Function: Verifies bottle Host XDG isn't on and bottle is not default.
#
# Input:
#	Arg1	 Bottle Name.
#	Arg2	 Global Variable Array name.
#	Arg3	 Strings Array name.
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function IsNotXdgDefault()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_RetStat=$WM_ERR_NONE
	local l_BottlePathname=""
	local l_TmpStr=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\"."
																# Bottle pathname
	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
	DbgPrint "${FUNCNAME[0]}: Bottle pathname = \"$l_BottlePathname\"."
																# Get default bottle name
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_DFLT]}" "l_TmpStr" "${l_StrAry[$E_STR_WM_CONF_FILE]}"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\", File = \"${l_StrAry[$E_STR_WM_CONF_FILE]}\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
	DbgPrint "${FUNCNAME[0]}: Read default bottle from conf file \"$l_TmpStr\"."
																# If bottle is default
	if [ "$l_BottleName" ==  "$l_TmpStr" ]; then
																# Return error code
		ErrAdd $WM_ERR_BTL_ISDFLT "" "${!l_GlblVarAry}"
		DbgPrint "${FUNCNAME[0]}:Returning with error \"WM_ERR_BTL_ISDFLT\", value \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi
																# Get bottle XDG enable
	KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_TmpStr" "$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
	DbgPrint "${FUNCNAME[0]}: Read XDG enable from conf file \"$l_TmpStr\"."

	if [ $l_TmpStr -eq $GC_BTL_XDG_ENB ]; then	# If XDG enabled
																# Return error code
		ErrAdd $WM_ERR_BTL_XDGENB "" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*				  Verify Bottle Host XDG Not On And Not Default Or System			 *
#*******************************************************************************
#
# Function: Verifies bottle Host XDG isn't on and bottle is not default.
#
# Input:
#	Arg1	Bottle Name.
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	No parameters are passed.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function IsNotXdgDefaultSys()
{
	local l_BottleName="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"

																# If not system bottle
	if IsNotSys "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"; then
																# Check if XDG enabled or default
		IsNotXdgDefault "$l_BottleName" "${!l_GlblVarAry}" "${!l_StrAry}"
	fi	

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*												List Bottles										 *
#*******************************************************************************
#
# Input:
#	Arg1	List Type: 0 = bottle list, 1 = Backup bottle list 
#	Arg2	Global Variable Array name.
#	Arg3	Strings Array name.
#
# Output:
#	No parameters are passed.
#
# Exit Status:
#	Standard Wine Manager return status.
function BottleList()
{
	local l_OutType="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleDir=""
	local l_LblName=""
	local l_LenName=0
	local l_BottleName=""
	local l_BottlePathname=""
	local l_BottleDflt=""
	local l_Len=0
	local l_ConfFile=""
	local l_WineDir=""
	local l_Submenu=""
	local l_Env=""
	local l_Xdg=""
	local l_Dflt=""
	local l_Str=""
	local l_TmpInt=0
	local l_BottleAry=()
	local l_Ary=()
	local l_DspAry=()
	local l_ArySize=0

	local l_i=0
	local l_iName=0										# List Name array index
	local l_iVer=1											# List Version array index
	local l_iSub=2											# List Submenu array index
	local l_iEnv=3											# List Env array index
	local l_iAct=4											# List Active array index
	local l_iDflt=5										# List Default array index

	local l_LstLblName="Bottle Name"					# List Name string size
	local l_LstLblNameBack="Backup Bottle Name"	# List Backup Name string size
	local l_LstLblVer="Wine Version"					# List Version string size
	local l_LstLblSub="Submenu"						# List Submenu string size
	local l_LstLblEnv="Env File"						# List Env string size
	local l_LstLblXdg="Host XDG"						# List XDG string size
	local l_LstLblDflt="Default"						# List Default string size
																# List Name string size
	local l_LstLenName=`expr length "$l_LstLblName"`
																# List Name string size
	local l_LstLenNameBack=`expr length "$l_LstLblNameBack"`
																# List Version string size
	local l_LstLenVer=`expr length "$l_LstLblVer"`
																# List Submenu string size
	local l_LstLenSub=`expr length "$l_LstLblSub"`
																# List Env string size
	local l_LstLenEnv=`expr length "$l_LstLblEnv"`
																# List Active string size
	local l_LstLenXdg=`expr length "$l_LstLblXdg"`
																# List Default string size
	local l_LstLenDflt=`expr length "$l_LstLblDflt"`

	local l_Sep="	"										# Column seperator string
	local l_CsName=0										# Initial Name column size
	local l_CsWineDir=$l_LstLenVer					# Initial Version column size
	local l_CsSub=$l_LstLenSub							# Initial Submenu column size
	local l_BtlType=""									# Column seperator string

	DbgPrint "${FUNCNAME[0]}: Entered."

	if [ $l_OutType -eq 0 ]; then						# If main bottles output
		l_BottleDir="${l_StrAry[$E_STR_WM_BTL_DIR]}"
		l_LblName=$l_LstLblName
		l_LenName=$l_LstLenName
		l_BtlType="bottles"
	else														# If backup bottles output
		l_BottleDir="${l_StrAry[$E_STR_WM_BTL_BCKP_DIR]}"
		l_LblName=$l_LstLblNameBack
		l_LenName=$l_LstLenNameBack
		l_BtlType="backup bottles"
	fi

	l_BottleAry=(`ls -1 "$l_BottleDir"`)			# Get bottle array
	if [ ${#l_BottleAry[@]} -eq 0 ]; then			# If no bottles
		MsgAdd $GC_MSGT_SUCCESS "There are no $l_BtlType" "${!l_GlblVarAry}"
	else
		DbgPrint "${FUNCNAME[0]}: Number of bottles = \"${#l_BottleAry[@]}\""
		l_Sep="  "											# List Column seperator
		l_CsName=$l_LenName								# Initial Name column size
		l_CsWineDir=$l_LstLenVer						# Initial Version column size
		l_CsSub=$l_LstLenSub								# Initial Submenu column size
																# Get default wine bottle
		KeyRd "${l_StrAry[$E_STR_KEY_BTL_DFLT]}" "l_BottleDflt" "${l_StrAry[$E_STR_WM_CONF_FILE]}"
		l_RetStat=$?
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_DFLT]}\", Value = \"\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi	

		l_i=0													# Init array index

		l_BottleAry=(`ls -1 "$l_BottleDir"`)		# Get bottle array
		for l_BottleName in "${l_BottleAry[@]}"; do
			DbgPrint "${FUNCNAME[0]}: Bottle name=\"$l_BottleName\""
																# Bottle pathname
			l_BottlePathname="$l_BottleDir/$l_BottleName"
																# Bottle conf file pathname
			l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"

# Name Processing
# ---------------
			DbgPrint "${FUNCNAME[0]}: Bottle pathname=\"$l_BottlePathname\""
			l_Len=${#l_BottleName}						# Get name string length
			DbgPrint "${FUNCNAME[0]}: Bottle name length=\"$l_Len\""
			if [ $l_Len -gt $l_CsName ]; then		# If longest so far
				l_CsName=$l_Len							# Set new column size
				DbgPrint "${FUNCNAME[0]}: New name column length=\"$l_CsName\""
			fi

# Wine Directory Processing
# -------------------------
																# Get bottle wine version
			KeyRd "${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}" "l_WineDir" "$l_ConfFile"
			l_RetStat=$?
			if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
				ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi	

			l_Len=${#l_WineDir}							# Get string length
			DbgPrint "${FUNCNAME[0]}: Real wine version length=\"$l_Len\""
			if [ $l_Len -eq 0 ]; then					# If no version
				l_WineDir="Default"						# Set default ver
			fi

			DbgPrint "${FUNCNAME[0]}: Bottle \"$l_BottleName\" wine version=\"$l_WineDir\""
			l_Len=${#l_WineDir}							# Get string length
			DbgPrint "${FUNCNAME[0]}: Adjusted wine version length=\"$l_Len\""
			if [ $l_Len -gt $l_CsWineDir ]; then	# If longest so far
				l_CsWineDir=$l_Len						# Set new column size
				DbgPrint "${FUNCNAME[0]}: New wine version column length=\"$l_CsWineDir\""
			fi

# Default Bottle Processing
# -------------------------
																# If not default bottle
			if [ "$l_BottleName" != "$l_BottleDflt" ]; then
				l_Dflt="No"									# Set default to no
			else
				l_Dflt="Yes"								# Set default to yes
			fi

# Submenu Processing
# -------------------
																# Get submenu
			KeyRd "${l_StrAry[$E_STR_KEY_BTL_SMENU]}" "l_Submenu" "$l_ConfFile"
			l_RetStat=$?
			if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
				ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_SMENU]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi	

			l_Len=${#l_Submenu}							# Get string length
			DbgPrint "${FUNCNAME[0]}: Real submenu length=\"$l_Len\""
			if [ $l_Len -eq 0 ]; then					# If no submenu
				l_Submenu="None"							# Set no submenu
			fi
			DbgPrint "${FUNCNAME[0]}: Bottle \"$l_BottleName\" submenu=\"$l_Submenu\""
			l_Len=${#l_Submenu}							# Get string length
			DbgPrint "${FUNCNAME[0]}: Adjusted submenu length=\"$l_Len\""
			if [ $l_Len -gt $l_CsSub ]; then			# If longest so far
				l_CsSub=$l_Len								# Set new column size
				DbgPrint "${FUNCNAME[0]}: New submenu column length=\"$l_CsSub\""
			fi

# Environment File Processing
# ---------------------------
																# Get env file 
			KeyRd "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "l_Env" "$l_ConfFile"
			l_RetStat=$?
			if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
				ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
				return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
			fi	

			DbgPrint "${FUNCNAME[0]}: Environment file name=\"$l_Env\""
			if [ ! -z "$l_Env" ]; then					# If we have env file
				DbgPrint "${FUNCNAME[0]}: Bottle \"$l_BottleName\" has environment file"
				l_Env="Yes"									# Set env to yes
			else
				DbgPrint "${FUNCNAME[0]}: Bottle \"$l_BottleName\" doesn't have environment file"
				l_Env="No"									# Set env to no
			fi

# XDG Processing
# --------------
			if [ $l_OutType -eq 0 ]; then				# If main bottles output
																# Get XDG status
																# Get Bottle XDG enable key
				KeyRd "${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}" "l_Xdg" "$l_ConfFile"
				l_RetStat=$?
				if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
					ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi	
																# If bottle XDG enabled
				if [ $l_Xdg -eq $GC_BTL_XDG_ENB ]; then
					DbgPrint "${FUNCNAME[0]}: Bottle \"$l_BottleName\" XDG is enabled"
					l_Xdg="On"								# Set XDG on
				else
					DbgPrint "${FUNCNAME[0]}: Bottle \"$l_BottleName\" XDG is disabled"
					l_Xdg="Off"								# Set XDG off
				fi
																# Add bottle to display array
				l_Ary[l_i]="$l_BottleName\n$l_WineDir\n$l_Submenu\n$l_Env\n$l_Xdg\n$l_Dflt"
			else
																# Add bottle to display array
				l_Ary[l_i]="$l_BottleName\n$l_WineDir\n$l_Submenu\n$l_Env"
			fi
			((l_i++))
		done

		KeyRd "${l_StrAry[$E_STR_KEY_WM_INIT]}" l_TmpInt "${l_StrAry[$E_STR_WM_CONF_FILE]}"
		l_RetStat=$?
		if [ $l_RetStat -ne $GC_KF_ERR_NONE ]; then
															# Return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyAdd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_WM_INIT]}\", File = \"${l_StrAry[$E_STR_WM_CONF_FILE]}\"" "${!l_GlblVarAry}"
			return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
		fi

		echo ""
		l_Str="Wine Manager Initialized: "
		if [ $l_TmpInt -eq 0 ]; then				# If Wine Manager not initialized
			l_Str="${l_Str}No"
		else
			l_Str="${l_Str}Yes"
		fi
		echo "$l_Str."

		echo ""
		CenterStr "$l_LblName" $l_CsName  l_Str	# Name label print
		echo -n "$l_Str"
		echo -n "$l_Sep"

		CenterStr "$l_LstLblVer" $l_CsWineDir  l_Str	# Version label print
		echo -n "$l_Str"
		echo -n "$l_Sep"

		CenterStr "$l_LstLblSub" $l_CsSub  l_Str	# Submenu label print
		echo -n "$l_Str"
		echo -n "$l_Sep"
																# Env label print
		CenterStr "$l_LstLblEnv" $l_LstLenEnv  l_Str
		echo -n "$l_Str"

		if [ $l_OutType -eq 0 ]; then					# If main bottles output
			echo -n "$l_Sep"
																# Active label print
			CenterStr "$l_LstLblXdg" $l_LstLenXdg  l_Str
			echo -n "$l_Str"
			echo -n "$l_Sep"
																# Default label print
			CenterStr "$l_LstLblDflt" $l_LstLenDflt  l_Str
			echo -n "$l_Str"
		fi
		echo ""

		printf '%*s' $l_CsName | tr ' ' '-'			# Name label underline
		echo -n "$l_Sep"

		printf '%*s' $l_CsWineDir | tr ' ' '-'			# Version label underline
		echo -n "$l_Sep"

		printf '%*s' $l_CsSub | tr ' ' '-'			# Submenu label underline
		echo -n "$l_Sep"

		printf '%*s' $l_LstLenEnv | tr ' ' '-'		# Environment label underline

		if [ $l_OutType -eq 0 ]; then					# If main bottles output
			echo -n "$l_Sep"
			printf '%*s' $l_LstLenXdg | tr ' ' '-'	# Active label underline
			echo -n "$l_Sep"
																# Default label underline
			printf '%*s' $l_LstLenDflt | tr ' ' '-'
		fi
		echo ""

		l_ArySize=${#l_Ary[@]}							# Print bottle list
		#DbgPrint "${FUNCNAME[0]}: Print array size = \"$l_ArySize\""
		for ((l_i=0; l_i < l_ArySize; l_i++)); do
			IFS=$'\n' l_DspAry=( `echo -e "${l_Ary[l_i]}"` )
			if [ $l_OutType -eq 0 ]; then				# If main bottles output

				printf "%-${l_CsName}s$l_Sep%-${l_CsWineDir}s$l_Sep%-${l_CsSub}s$l_Sep%-${l_LstLenEnv}s$l_Sep%-${l_LstLenXdg}s$l_Sep%-${l_LstLenDflt}s\n" \
				"${l_DspAry[l_iName]}" "${l_DspAry[l_iVer]}" "${l_DspAry[l_iSub]}" "${l_DspAry[l_iEnv]}" "${l_DspAry[l_iAct]}" "${l_DspAry[l_iDflt]}"
			else												# If backup bottles output
				printf "%-${l_CsName}s$l_Sep%-${l_CsWineDir}s$l_Sep%-${l_CsSub}s$l_Sep%-${l_LstLenEnv}s\n" \
				"${l_DspAry[l_iName]}" "${l_DspAry[l_iVer]}" "${l_DspAry[l_iSub]}" "${l_DspAry[l_iEnv]}"
			fi
		done
		echo ""
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*									List Configuration Variables								 *
#*******************************************************************************
#
# Input:
#	Arg1	Configuration Variable Name. If null all bottle variables are
#			displayed.
#	Arg2	Protected configuration variable array name.
#	Arg3	Writeable configuration variable array name.
#	Arg4	Global Variable Array name.
#	Arg5	Strings Array name.
#	Arg6	Optional Bottle array Name.
#
# Output:
#	No parameters are passed.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function ConfVarList()
{
	local l_ConfVarName="$1"
	local -n l_CVarPAry="$2"
	local -n l_CVarWAry="$3"
	local -n l_GlblVarAry="$4"
	local -n l_StrAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_BottleDir=""
	local l_BottleName=""
	local l_BottlePathname=""
	local l_VarName=""
	local l_VarVal=""
	local l_VarType=""
	local -a l_VarNameAry=()
	local -a l_VarValAry=()
	local l_ConfFile=""
	local l_Len=0
	local l_Str=""
	local l_TmpInt=0
	local l_TmpFlg=0
	local l_DataAry=()
	local l_DspAry=()
	local l_DataArySize=0
	local l_OldIFS=""

	local l_iVarAry=0
	local l_i=0
	local l_ElmSize=4										# Data array element size
	local l_iBtlName=0									# List bottle name array index
	local l_iVarName=1									# List variable name array index
	local l_iVarVal=2										# List variable value array index
	local l_iVarType=3									# List variable type array index

	local l_LstLblBtlName="Bottle"					# List bottle name string
	local l_LstLblVarName="Variable"					# List variable name string
	local l_LstLblVarVal="Value"						# List value string
	local l_LstLblVarType="Type"						# List variable type string
																# List bottle Name string size
	local l_LstLenBtlName=`expr length "$l_LstLblBtlName"`
																# List variable name string size
	local l_LstLenVarName=`expr length "$l_LstLblVarName"`
																# List variable value string size
	local l_LstLenVarVal=`expr length "$l_LstLblVarVal"`
																# List variable type string size
	local l_LstLenVarType=`expr length "$l_LstLblVarType"`

	local l_Sep="	"										# Column seperator string
	local l_CsBtlName=0									# Initial bottle name column size
	local l_CsVarName=$l_LstLenVarName				# Initial variable name column size
	local l_CsVarVal=$l_LstLenVarVal					# Initial variable value column size
	local l_CsVarType=$l_LstLenVarType				# Initial variable type column size
	local l_BottleMode=0									# Default is Window Manager mode

	DbgPrint "${FUNCNAME[0]}: Entered."

	l_TmpFlg=0												# No exit request
	if [ ! -z "${6-}" ]; then							# If bottle array passed
		local -n l_BottleAry="$6"						# Point to it
		if [ ${#l_BottleAry[@]} -eq 0 ]; then		# If no bottles
			MsgAdd $GC_MSGT_INFO "There are no bottles" "${!l_GlblVarAry}"
			l_TmpFlg=1										# Request exit
		else
			l_BottleMode=1									# Set bottle mode
																# Set bottle dir
			l_BottleDir="${l_StrAry[$E_STR_WM_BTL_DIR]}"
			DbgPrint "${FUNCNAME[0]}: Number of bottles = \"${#l_BottleAry[@]}\""
		fi
	else														# If Wine Manager mode
		l_BottleName="Wine Manager"					# Fake bottle entry
		local -a l_BottleAry=( "$l_BottleName" )
	fi

	if [ $l_TmpFlg -eq 0 ]; then						# If no exit request

		l_Sep="  "											# List Column seperator
		l_CsBtlName=$l_LstLenBtlName					# Initial Name column size
		l_CsVarName=$l_LstLenVarName					# Initial variable name column size
		l_CsVarVal=$l_LstLenVarVal						# Initial variable value column size
		l_CsVarType=$l_LstLenVarVal					# Initial variable value column size

		l_TmpFlg=1											# Set first pass flag
		l_i=0													# Init array index
		for l_BottleName in "${l_BottleAry[@]}";
		do
			DbgPrint "${FUNCNAME[0]}: Bottle name=\"$l_BottleName\""

# Conf File Processing
# --------------------
			if [ $l_BottleMode -eq 1 ]; then			# If bottle mode
																# Bottle pathname
				l_BottlePathname="$l_BottleDir/$l_BottleName"
																# Bottle conf file pathname
				l_ConfFile="$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"

				DbgPrint "${FUNCNAME[0]}: Bottle pathname=\"$l_BottlePathname\""
				l_Len=${#l_BottleName}					# Get name string length
				DbgPrint "${FUNCNAME[0]}: Bottle name length=\"$l_Len\""
																# If longest so far
				if [ $l_Len -gt $l_CsBtlName ]; then
					l_CsBtlName=$l_Len					# Set new column size
					DbgPrint "${FUNCNAME[0]}: New name column length=\"$l_CsBtlName\""
				fi
			else												# If Wine Manager mode
				l_ConfFile="${l_StrAry[$E_STR_WM_CONF_FILE]}"
			fi

# Variable Processing
# -------------------
			l_VarNameAry=()								# Clear variable arrays
			l_VarValAry=()

			if [ ! -z "$l_ConfVarName" ]; then		# If we have an input var name
																# Read value
				KeyRd "$l_ConfVarName" l_Str "$l_ConfFile"
				l_RetStat=$?
																# If error other than key doesn't exist
				if [[ $l_RetStat -ne $GC_KF_ERR_NONE && $l_RetStat -ne $GC_KF_ERR_KEY_NEXIST ]];then
																# Return Standard Script error code
					ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
																# If we got a value
				if [ $l_RetStat -eq $GC_KF_ERR_NONE ];then
																# Add to name array
					l_VarNameAry=( "$l_ConfVarName" )
					l_VarValAry=( "$l_Str" )			# Add to value array
				fi
			else												# Otherwise get all var names and values
				KeyRdAll "$l_ConfFile" l_VarNameAry l_VarValAry
				l_RetStat=$?
																# If error other than key doesn't exist
				if [[ $l_RetStat -ne $GC_KF_ERR_NONE && $l_RetStat -ne $GC_KF_ERR_KEY_NEXIST ]];then
																# Return Standard Script error code
					ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Status = \"$l_RetStat\", Key = \"${l_StrAry[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$l_ConfFile\"" "${!l_GlblVarAry}"
					return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
				fi
			fi	

			if [ ${#l_VarNameAry[@]} -gt 0 ]; then	# If we have variables

				if [ $l_TmpFlg -eq 0 ]; then			# If not first pass
					l_DataAry[((l_i+l_iBtlName))]=""	# Add blank line to data array
					l_DataAry[((l_i+l_iVarName))]=""
					l_DataAry[((l_i+l_iVarVal))]=""
					l_DataAry[((l_i+l_iVarType))]=""
					l_i=$((l_i+l_ElmSize))				# Inc data array
				else											# If first pass
					l_TmpFlg=0								# Clear first pass flag
				fi

				l_iVarAry=0									# Init name/value index
				for l_VarName in "${l_VarNameAry[@]}";
				do												# Go through all variable names
																# Get value
					l_VarVal="${l_VarValAry[l_iVarAry]}"
					DbgPrint "${FUNCNAME[0]}: Variable Name=\"$l_VarName\",  Variable Value=\"$l_VarVal\""

					l_Len=${#l_VarName}					# Get string length
					DbgPrint "${FUNCNAME[0]}: Variable Name length=\"$l_Len\""
																# If longest so far
					if [ $l_Len -gt $l_CsVarName ]; then
						l_CsVarName=$l_Len				# Set new column size
						DbgPrint "${FUNCNAME[0]}: New Variable Name column length=\"$l_CsVarName\""
					fi

					l_Len=${#l_VarVal}					# Get string length
					DbgPrint "${FUNCNAME[0]}: Variable Value length=\"$l_Len\""
																# If longest so far
					if [ $l_Len -gt $l_CsVarVal ]; then
						l_CsVarVal=$l_Len					# Set new column size
						DbgPrint "${FUNCNAME[0]}: New Variable Value column length=\"$l_CsVarVal\""
					fi
																# Get variable type
					VarTypeChk "$l_VarName" ${!l_CVarPAry} ${!l_CVarWAry}
					case $? in 
						$GC_FUNCS_VarTypeChk_P)
							l_VarType="System (Protected)"
						;;

						$GC_FUNCS_VarTypeChk_W)
							l_VarType="System"
						;;

						$GC_FUNCS_VarTypeChk_U)
							l_VarType="User"
						;;

					esac

					l_Len=${#l_VarType}					# Get string length
					DbgPrint "${FUNCNAME[0]}: Variable Type length=\"$l_Len\""
																# If longest so far
					if [ $l_Len -gt $l_CsVarType ]; then
						l_CsVarType=$l_Len				# Set new column size
						DbgPrint "${FUNCNAME[0]}: New Variable Type column length=\"$l_CsVarType\""
					fi
																# Add element to data array
					l_DataAry[((l_i+l_iBtlName))]="$l_BottleName"
					l_DataAry[((l_i+l_iVarName))]="$l_VarName"
					l_DataAry[((l_i+l_iVarVal))]="$l_VarVal"
					l_DataAry[((l_i+l_iVarType))]="$l_VarType"
					l_i=$((l_i+l_ElmSize))				# Inc data array
					((l_iVarAry++))						# Inc variable array
					l_BottleName=""						# Only write bottle name once
				done
			fi
		done

		l_TmpInt=${#l_DataAry[@]}						# Get data array size
		if [ $l_TmpInt -eq 0 ]; then
			MsgAdd $GC_MSGT_INFO "There are no variables to display" "${!l_GlblVarAry}"
		else													# If we have variables
																# Get element size
			l_DataArySize=$(($l_TmpInt / $l_ElmSize))

# Write Display Label
# -------------------
			echo ""											# Seperator line
			if [ $l_BottleMode -eq 1 ]; then			# If bottle mode
																# Bottle name label print
				CenterStr "$l_LstLblBtlName" $l_CsBtlName  l_Str
				echo -n "$l_Str"
				echo -n "$l_Sep"
			fi
																# Variable name label print
			CenterStr "$l_LstLblVarName" $l_CsVarName  l_Str
			echo -n "$l_Str"
			echo -n "$l_Sep"
																# Variable value label print
			CenterStr "$l_LstLblVarVal" $l_CsVarVal  l_Str
			echo -n "$l_Str"
			echo -n "$l_Sep"
																# Variable type label print
			CenterStr "$l_LstLblVarType" $l_CsVarType  l_Str
			echo -n "$l_Str"
			echo ""

			if [ $l_BottleMode -eq 1 ]; then			# If bottle mode
																# Bottle name label underline
				printf '%*s' $l_CsBtlName | tr ' ' '-'
				echo -n "$l_Sep"
			fi
			
			printf '%*s' $l_CsVarName | tr ' ' '-'	# Variable name label underline
			echo -n "$l_Sep"

			printf '%*s' $l_CsVarVal | tr ' ' '-'	# Variable value label underline
			echo -n "$l_Sep"

			printf '%*s' $l_CsVarType | tr ' ' '-'	# Variable type label underline
			echo ""

#			DbgPrint "${FUNCNAME[0]}: Print array size = \"$l_DataArySize\""
			for ((l_i=0; l_i < l_DataArySize; l_i++)); do
#				DbgPrint "${FUNCNAME[0]}: Info Array Index \"$l_i\" = \"${l_DataAry[l_i]}\"" 1

				l_TmpInt=$((l_i * l_ElmSize))
				l_DspAry[l_iBtlName]="${l_DataAry[((l_TmpInt+l_iBtlName))]}"
				l_DspAry[l_iVarName]="${l_DataAry[((l_TmpInt+l_iVarName))]}"
				l_DspAry[l_iVarVal]="${l_DataAry[((l_TmpInt+l_iVarVal))]}"
				l_DspAry[l_iVarType]="${l_DataAry[((l_TmpInt+l_iVarType))]}"

				if [ $l_BottleMode -eq 1 ]; then		# If bottle mode
					printf "%-${l_CsBtlName}s$l_Sep%-${l_CsVarName}s$l_Sep%-${l_CsVarVal}s$l_Sep%-${l_CsVarType}s\n" \
					"${l_DspAry[l_iBtlName]}" "${l_DspAry[l_iVarName]}" "${l_DspAry[l_iVarVal]}" "${l_DspAry[l_iVarType]}"
				else											# If Wine Manager mode
					printf "%-${l_CsVarName}s$l_Sep%-${l_CsVarVal}s$l_Sep%-${l_CsVarType}s\n" \
					"${l_DspAry[l_iVarName]}" "${l_DspAry[l_iVarVal]}" "${l_DspAry[l_iVarType]}"
				fi
			done
			echo ""
		fi
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*		Insert Environment Into All Bottle Desktop Files From Standard File		 *
#*******************************************************************************
#
# Function: Inserts bottle environment into all bottle desktop files.
#
# Input:
#	Arg1	 Bottle pathname.
#	Arg2	 Global Variable Array name.
#	Arg3	 Strings Array name.
#	Arg4	 XDG Directory Array name
#	Arg5	 XDG Desktop File Subpath Array name
#
# Output:
#	Arg2	E_GLBL_ERR_CODE = error code.
#
# Exit Status:
#	Standard Wine Manager return status.
#
function BottleEnvInsertStandard()
{
	local l_BottlePathname="$1"
	local -n l_GlblVarAry="$2"
	local -n l_StrAry="$3"
	local -n l_XdgDirAry="$4"
	local -n l_XdgDsktpSubpathAry="$5"
	local l_RetStat=$WM_ERR_NONE
	local l_EnvNameFile=""
	local l_EnvFile=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle \"$l_BottlePathname\"."

	KeyRd "${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}" "l_EnvFile" "$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}"
	l_RetStat=$?
	if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
		ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "${FUNCNAME[0]}${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${l_StrAry[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$l_BottlePathname/${l_StrAry[$E_STR_BTL_CONF_FILE]}\"" "${!l_GlblVarAry}"
		return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
	fi	
	DbgPrint "${FUNCNAME[0]}: Environment file name: \"$l_EnvFile\""
															# Insert env in desktop files
	BottleEnvInsert "$l_BottlePathname" "$l_EnvFile" "${!l_XdgDirAry}" "${!l_XdgDsktpSubpathAry}"

	DbgPrint "${FUNCNAME[0]}: Exiting with status \"${l_GlblVarAry[$E_GLBL_ERR_CODE]}\"."
	return ${l_GlblVarAry[$E_GLBL_ERR_CODE]}
}

#*******************************************************************************
#*										Launch Console Subshell									 *
#*******************************************************************************
#
# Function: Invokes shell in bottle environment.
#
# Input:
#	Arg1	 Bottle name.
#	Arg2	 Environment file pathname.
#	Arg3	 Strings Array name.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function BottleLaunchShell()
{
	local l_BottleName="$1"
	local l_EnvFile="$2"
	local -n l_StrAry="$3"
	local l_TermTitle=""
	local l_CmdPrompt=""
	local l_BottlePathname=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle name \"$l_BottleName\", environment file \"$l_EnvFile\"."

	l_BottlePathname="${l_StrAry[$E_STR_WM_BTL_DIR]}/$l_BottleName"
	DbgPrint "l_BottlePathname=\"$l_BottlePathname\""

	export WINEPREFIX="$l_BottlePathname/wine"	# Set Wine prefix
	DbgPrint "WINEPREFIX=$WINEPREFIX"

	if [ ! -z "$l_EnvFile" ]; then					# If we have env file
	  DbgPrint "${FUNCNAME[0]}: Sourcing environment file: $l_EnvFile"
	  source "$l_EnvFile"								# Source variables
	fi

# Green
#	l_CmdPrompt="\[\033[01;32m\][\u@'$l_BottleName'\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] "
# Yellow
#	l_CmdPrompt="\[\033[01;33m\][\u@'$l_BottleName'\[\033[01;37m\] \W\[\033[01;33m\]]\$\[\033[00m\] "
# Cyan
	l_CmdPrompt="\[\033[01;36m\][\u@'$l_BottleName'\[\033[01;37m\] \W\[\033[01;36m\]]\$\[\033[00m\] "
	l_TermTitle='echo -ne "\033]0;${USER}@'$l_BottleName':${PWD/#$HOME/\~}\007"'
	bash --rcfile <(echo "export PROMPT_COMMAND='$l_TermTitle';export PS1=$'$l_CmdPrompt'; cd $l_BottlePathname")

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*						Insert Environment Setup Into Desktop File						 *
#*******************************************************************************
#
# Function: Inserts bottle environment in desktop file.
#
# Input:
#	Arg1	 Desktop file pathname.
#	Arg2	 Environment file pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function InsertEnvDesktop()
{
	local l_DesktopFile="$1"
	local l_EnvFile="$2"

	DbgPrint "${FUNCNAME[0]}: Entered with desktop file \"$l_DesktopFile\", environment file \"$l_EnvFile\"."
						# If environment setup needed
	if [ ! -z "$l_EnvFile" ] && ! grep "Exec=bash -c \"source" "$l_DesktopFile" >/dev/null 2>&1; then

		DbgPrint "${FUNCNAME[0]}: Desktop file \"$l_DesktopFile\" needs environment setup, inserting."

		DeleteEnvDesktop "$l_DesktopFile"	# Delete any exisiting env

		DbgPrint "${FUNCNAME[0]}: Inserting environment file \"$l_EnvFile\" into \"$l_DesktopFile\"."
						# Insert "bash -c" start
		sed -i "s#Exec=#&bash -c \"source $l_EnvFile \&\& #" "$l_DesktopFile"
						# Append ending double quote
		sed -i "/Exec=/ s/$/\"/" "$l_DesktopFile"
						# Single quote "\\\\"
		sed -i '/Exec=/ s#\\\\\\\\#'"'"'\\\\\\\\'"'"'#g' "$l_DesktopFile"
	fi
	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*						Delete Environment Setup From Desktop File						 *
#*******************************************************************************
#
# Function: Deletes bottle environment from desktop file.
#
# Input:
#	Arg1	 Desktop file pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function DeleteEnvDesktop()
{
	local l_DesktopFile="$1"

	DbgPrint "${FUNCNAME[0]}: Entered with desktop file \"$l_DesktopFile\"."

	if grep "Exec=bash" "$l_DesktopFile" >/dev/null 2>&1; then
		DbgPrint "${FUNCNAME[0]}: Desktop file \"$l_DesktopFile\" environment setup detected, deleting."
						# Delete "bash" command start
		sed -i "s#Exec=bash.*\&\& #Exec=#" "$l_DesktopFile"
		sed -i "/Exec=/ s/.$//" "$l_DesktopFile"	# Delete ending double quote
						# Unquote "\\\\"
		sed -i '/Exec=/ s#'"'"'\\\\\\\\'"'"'#\\\\\\\\#g' "$l_DesktopFile"
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*						Insert Environment Into All Bottle Desktop Files				 *
#*******************************************************************************
#
# Function: Inserts bottle environment into all bottle desktop files.
#
# Input:
#	Arg1	 Bottle pathname.
#	Arg2	 Environment file pathname.
#	Arg3	 XDG Directory Array name
#	Arg4	 XDG Desktop File Subpath Array name
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function BottleEnvInsert()
{
	local l_BottlePathname="$1"
	local l_EnvFile="$2"
	local -n l_XdgDirAry="$3"
	local -n l_XdgDsktpSubpathAry="$4"
	local XdgDsktpSubpath=""
	local l_DesktopFile=""
	local l_XdgDsktpSubpath=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle \"$l_BottlePathname\", environment file \"$l_EnvFile\"."

	if [ -z "$l_EnvFile" ]; then						# If no env file
		DbgPrint "${FUNCNAME[0]}: Bottle \"$l_BottlePathname\" doesn't have an environment file, deleting environment setup."
		BottleEnvDelete "$l_BottlePathname" "${!l_XdgDirAry}" "${!l_XdgDsktpSubpathAry}"
	else
		for l_XdgDsktpSubpath in "${l_XdgDsktpSubpathAry[@]}"
		do
			DbgPrint "${FUNCNAME[0]}: Inserting environment setup '$l_EnvFile' into all bottle '$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}/$l_XdgDsktpSubpath' .desktop files"
			cd "$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}/$l_XdgDsktpSubpath"
			find . -print | grep -i '.desktop' | while read l_DesktopFile
			do
				DbgPrint "${FUNCNAME[0]}: Processing desktop file '$l_DesktopFile'."
				InsertEnvDesktop "$l_DesktopFile" "$l_EnvFile"
			done
		done
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*				Delete Environment Setup From All Bottle Desktop Files				 *
#*******************************************************************************
#
# Function: Deletes bottle environment from all bottle desktop files.
#
# Input:
#	Arg1	 Bottle pathname
#	Arg2	 XDG Directory Array name.
#	Arg3	 XDG Desktop File Subpath Array name
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function BottleEnvDelete()
{
	local l_BottlePathname="$1"
	local -n l_XdgDirAry="$2"
	local -n l_XdgDsktpSubpathAry="$3"
	local l_DesktopFile=""
	local l_XdgDsktpSubpath=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle \"$l_BottlePathname\"."

	for l_XdgDsktpSubpath in "${l_XdgDsktpSubpathAry[@]}"
	do
		cd "$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}/$l_XdgDsktpSubpath"
		find . -print | grep -i '.desktop' | while read l_DesktopFile
		do
			DbgPrint "${FUNCNAME[0]}: Processing desktop file '$l_DesktopFile'."
			DeleteEnvDesktop "$l_DesktopFile"
		done
	done

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*						Change Wine Version In All Bottle Desktop Files					 *
#*******************************************************************************
#
# Function: Changes wine executable in all bottle desktop files.
#
# Input:
#	Arg1	 Full bottle pathname
#	Arg2	 Wine executable pathname.
#	Arg3	 XDG Directory Array name.
#	Arg4	 XDG Desktop File Subpath Array name
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function ChangeWineExecBottle()
{
	local l_BottlePathname="$1"
	local l_WineExec="$2"
	local -n l_XdgDirAry="$3"
	local -n l_XdgDsktpSubpathAry="$4"
	local l_DesktopFile=""
	local l_XdgDsktpSubpath=""

	DbgPrint "${FUNCNAME[0]}: Entered with bottle \"$l_BottlePathname\", Wine executable \"$l_WineExec\"."

	for l_XdgDsktpSubpath in "${l_XdgDsktpSubpathAry[@]}"
	do
		cd "$l_BottlePathname/${l_XdgDirAry[$E_XDG_PRI_BOTTLE]}/$l_XdgDsktpSubpath"
		find . -print | grep -i '.desktop' | while read l_DesktopFile
		do
			DbgPrint "${FUNCNAME[0]}: Processing desktop file '$l_DesktopFile'."
			ChangeWineExecDesktop "$l_DesktopFile" "$l_WineExec"
		done
	done

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*							Change Wine Executable In Desktop File							 *
#*******************************************************************************
#
# Function: Changes wine executable in desktop file.
#
# Input:
#	Arg1	 Desktop file pathname.
#	Arg2	 Wine executable pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function ChangeWineExecDesktop()
{
	local l_DesktopFile="$1"
	local l_WineExec="$2"

	DbgPrint "${FUNCNAME[0]}: Entered with desktop file \"$l_DesktopFile\", Wine executable \"$l_WineExec\"."

	sed -i "/Exec=/ s#wine\" .*wine #wine\" $l_WineExec #" "$l_DesktopFile"

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*										Fuse Directory Mount Check								 *
#*******************************************************************************
#
# Function: Cehcks if a directory is mounted by fused.
#
# Input:
#	Arg1  Mount point pathname.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	 0 = Not mounted
#	 1 = Mounted
# 
function CheckFuseMount()
{
	local l_Dir="$1"
	local l_MountSystem=""
	local l_ExitStat=0

	DbgPrint "${FUNCNAME[0]}: Entered with mount point=\"$l_Dir\""
																# Get name of filesystem
	l_MountSystem=`df -P -T "$l_Dir" | tail -n +2 | awk '{print $2}'`
	if [ "$l_MountSystem" == "fuse" ]; then 		# If it's fuse
		DbgPrint "${FUNCNAME[0]}: Directory is mounted by fuse - \"$l_Dir\""
		l_ExitStat=1										# Exit with mounted status
	fi
	
	DbgPrint "${FUNCNAME[0]}: Exiting with Status = $l_ExitStat"
	return $l_ExitStat
}


#*******************************************************************************
#*												Message Clear										 *
#*******************************************************************************
#
# Function: Clears all message elements.
#
# Input:
#	Arg1	Global Variable Array name.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function MsgClear()
{
	local -n l_MsgClear_GVA="$1"
																# Last error code
	DbgPrint "${FUNCNAME[0]}: Entered."

	l_MsgClear_GVA[$E_GLBL_ERR_CODE]=$WM_ERR_NONE
	l_MsgClear_GVA[$E_GLBL_MSG_ARY_IDX]=-1			# Current message array index
																# Get message array
	local -n l_MsgClearAry="${l_MsgClear_GVA[$E_GLBL_MSG_ARY_NAME]}"
	l_MsgClearAry=( )										# Clear it

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*													Add Error										 *
#*******************************************************************************
#
# Function: Add error code to and optional error message to system messages.
#
# Input:
#	Arg1	Error code.
#	Arg2  Error message (optional).
#	Arg3  Global Variable Array name.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function ErrAdd()
{
	local l_ErrCode="$1"
	local l_ErrMsg="$2"
	local -n l_ErrAdd_GVA="$3"

	DbgPrint "${FUNCNAME[0]}: Entered with Error Code \"$l_ErrCode\",  Error Message \"$l_ErrMsg\"."

	l_ErrAdd_GVA[$E_GLBL_ERR_CODE]=$l_ErrCode		# Set last error code
																# Add it to messages
	MsgAdd $GC_MSGT_ERR_CODE "$l_ErrCode" "${!l_ErrAdd_GVA}"

	if [ ! -z "$l_ErrMsg" ]; then						# If error message isn't null
																# Add it to messages
		MsgAdd $GC_MSGT_ERR "$l_ErrMsg" "${!l_ErrAdd_GVA}"
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*						Add Mount Point To Host XDG Mount Queue Array					 *
#*******************************************************************************
#
# Function: Adds mount point to Host XDG Mount Queue array.
#
# Input:
#	Arg1	Mount point.
#	Arg2  Global Variable Array name.
#
# Output:
#	Mount point added to Host XDG Mount Queue array.
#
# Exit Status:
#	None.
#
function QueueHostXdgMount()
{
	local l_MountPoint="$1"
	local -n l_GlblVarAry="$2"

	DbgPrint "${FUNCNAME[0]}: Entered with mount point \"$l_MountPoint\"."
																# Get mount array
	local -n l_XdgMntAry="${l_GlblVarAry[$E_GLBL_XDG_MNT_ARY_NAME]}"
	l_XdgMntAry+=( "$l_MountPoint" )			# Write mount point

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*					Add Unmount Point To Host XDG Unmount Queue Array					 *
#*******************************************************************************
#
# Function: Adds unmount point to Host XDG Mount Queue array.
#
# Input:
#	Arg1	Unmount point.
#	Arg2  Global Variable Array name.
#
# Output:
#	Unmount point added to Host XDG Unmount Queue array.
#
# Exit Status:
#	None.
#
function QueueHostXdgUnmount()
{
	local l_UnmountPoint="$1"
	local -n l_GlblVarAry="$2"

	DbgPrint "${FUNCNAME[0]}: Entered with mount point \"$l_MountPoint\"."
																# Get mount array
	local -n l_XdgUmntAry="${l_GlblVarAry[$E_GLBL_XDG_UMNT_ARY_NAME]}"
	l_XdgUmntAry+=( "$l_UnmountPoint" )		# Write mount point

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*										Add Message To Message Array							 *
#*******************************************************************************
#
# Function: Add message string to message array.
#
# Input:
#	Arg1	Message type.
#	Arg2	Message string.
#	Arg3  Global Variable Array name.
#
# Output:
#	Message added .
#
# Exit Status:
#	None.
#
function MsgAdd()
{
	local l_MsgType="$1"
	local l_Msg="$2"
	local -n l_MsgAdd_GVA="$3"
	local l_Idx=0
	
	DbgPrint "${FUNCNAME[0]}: Entered with message type \"$l_MsgType\",  Message \"$l_Msg\"."
																# Get message array
	local -n l_MsgAry="${l_MsgAdd_GVA[$E_GLBL_MSG_ARY_NAME]}"

	((l_MsgAdd_GVA[$E_GLBL_MSG_ARY_IDX]++))		# Inc message index
	l_Idx=${l_MsgAdd_GVA[$E_GLBL_MSG_ARY_IDX]}	# Get index
																# Write message type and message
	l_MsgAry[$l_Idx]="${l_MsgType}${GC_MSG_CODE_TRM}${l_Msg}"

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*												Message Prepend									 *
#*******************************************************************************
#
# Function:Prepend message to message string.
#
# Input:
#	Arg1	New message string.
#	Arg2  Existing message string variable name.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function MsgPrepend()
{
	local l_MsgPrepend="$1"
	local -n l_MsgPrepend_GVA="$2"
	local l_Idx=0
	local l_MsgEntry=""
	local l_MsgType=0
	local l_MsgStr=""
	local l_OldIFS=""
	local -a l_MsgPartAry
	
	DbgPrint "${FUNCNAME[0]}: Entered with prepend message \"$l_MsgPrepend\"."
																# Get message array
	local -n l_MsgPrepend_MsgAry="${l_MsgPrepend_GVA[$E_GLBL_MSG_ARY_NAME]}"
																# Get index
	l_Idx=${l_MsgPrepend_GVA[$E_GLBL_MSG_ARY_IDX]}

	l_MsgEntry="${l_MsgPrepend_MsgAry[$l_Idx]}"	# Get message entry
	l_OldIFS="$IFS"
	IFS="$GC_MSG_CODE_TRM"
	l_MsgPartAry=( $l_MsgEntry )						# Seperate type from message
	IFS="$l_OldIFS"

	l_MsgType=${l_MsgPartAry[0]}						# Get message type
	l_MsgStr="${l_MsgPartAry[1]}"						# Get message string
	l_MsgStr="${l_MsgPrepend}${l_MsgStr}"			# Prepend message
																# Write message type and message
	l_MsgPrepend_MsgAry[$l_Idx]="${l_MsgType}${GC_MSG_CODE_TRM}${l_MsgStr}"

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*									Error Code to Message Decode								 *
#*******************************************************************************
#
# Function: Decode error code to message.
#
# Input:
#	Arg1	Error code.
#	Arg2	Message string variable name.
#
# Output:
#	Arg2	Error message.
#
# Exit Status:
#	None.
#
function ErrCodeToMsg()
{
	local l_ErrCode="$1"
	local -n l_ECTM_MsgStr="$2"
																# If not a Standard Script error
	if [ $l_ErrCode -lt $WM_ERR_TOTAL ]; then
																# Get Wine Manager error message
		l_ECTM_MsgStr="${l_ErrMsgAry[$l_ErrCode]}"
																# Else if Standard Script error						
	elif [ $l_ErrCode -lt $(($WM_ERR_TOTAL+$GC_KF_ERR_TOTAL)) ]; then
																# Subtract error code offset						
		l_ErrCode=$(($l_ErrCode - $WM_ERR_TOTAL))
																# Get Standard Script error message
		l_ECTM_MsgStr="${l_SsErrMsgAry[$l_ErrCode]}"
																# Else if Token Parser error
	elif [ $l_ErrCode -lt $(($WM_ERR_TOTAL+$GC_KF_ERR_TOTAL+$TP_ERR_TOTAL)) ]; then
																# Subtract error code offset						
		l_ErrCode=$(($l_ErrCode - $(($WM_ERR_TOTAL+$GC_KF_ERR_TOTAL))))
																# Get Token Parser error message
		l_ECTM_MsgStr="${l_TpErrMsgAry[$l_ErrCode]}"

	else										# If unknown error
		l_ECTM_MsgStr="Unknown error code \"$l_ErrCode\""
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*												Message Create										 *
#*******************************************************************************
#
# Function: Creates message from message structures.
#
# Input:
#	Arg1	Global Variable Array name.
#	Arg2	Wine Manager error message array.
#	Arg3	Standard Script error message array.
#	Arg4	Token Parser error message array.
#	Arg5	Exit message return variable name.
#
# Output:
#	Arg4	Error message.
#
# Exit Status:
#	None.
#
function MsgCreate()
{
	local -n l_GlblVarAry="$1"
	local -n l_ErrMsgAry="$2"
	local -n l_SsErrMsgAry="$3"
	local -n l_TpErrMsgAry="$4"
	local -n l_ExitMsg="$5"
	local l_Idx=0
	local l_MsgType=$GC_MSGT_NONE
	local l_MsgTypeLast=$GC_MSGT_NONE
	local l_OldIFS=""
	local l_MsgEntry=""
	local l_MsgStr=""
	local l_Prepend=""
	local -a l_MsgPartAry
	
	DbgPrint "${FUNCNAME[0]}: Entered."

	l_ExitMsg=""
																# Get message array
	local -n l_MsgAry="${l_GlblVarAry[$E_GLBL_MSG_ARY_NAME]}"
	l_NumOfMsgs=${#l_MsgAry[@]}						# Get number of messages

	for((l_Idx=0; l_Idx < $l_NumOfMsgs; l_Idx++))
	do
		l_MsgEntry="${l_MsgAry[$l_Idx]}"				# Get message entry
		l_OldIFS="$IFS"
		IFS="$GC_MSG_CODE_TRM"
		l_MsgPartAry=( $l_MsgEntry )					# Seperate type from message
		IFS="$l_OldIFS"

		DbgPrint "${FUNCNAME[0]}: Message Type = \"${l_MsgPartAry[0]}\", Message String = \"${l_MsgPartAry[1]}\"."

		l_MsgStr="${l_MsgPartAry[1]}"					# Get message string
																# If new message type
		if [ ${l_MsgPartAry[0]} -ne $l_MsgType ]; then
			l_MsgTypeLast=$l_MsgType					# Save last message type
			l_MsgType=${l_MsgPartAry[0]}				# Set new message type

			case "$l_MsgType" in							# Get message label
				$GC_MSGT_ERR_CODE)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBL_ERR]}"
					l_ErrCode=$l_MsgStr					# Get error code
					ErrCodeToMsg $l_ErrCode l_MsgStr	# Get error message
				;;

				$GC_MSGT_ERR)
																# If last message not error code
					if [ $l_MsgTypeLast -ne $GC_MSGT_ERR_CODE ]; then
																# Use label
						l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBL_ERR]}"
					else										# Else continue with spaces
						l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBLSPC_ERR]}"
					fi
				;;

				$GC_MSGT_HELP)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBL_HELP]}"
				;;

				$GC_MSGT_INFO)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBL_INFO]}"
				;;

				$GC_MSGT_SUCCESS)
					l_Prepend=""
				;;

				$GC_MSGT_USAGE)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBL_USAGE]}"
				;;

				$GC_MSGT_WARN)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBL_WARN]}"
				;;

				*)
					l_Prepend="INTERNAL ERROR"
				;;
			esac
		else													# If same message type as before

			case "$l_MsgType" in							# Get label spaces
				$GC_MSGT_ERR_CODE)
																# Always use label for error code
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBL_ERR]}"
					l_ErrCode=$l_MsgStr					# Get error code
					ErrCodeToMsg $l_ErrCode l_MsgStr	# Get error message
				;;

				$GC_MSGT_ERR)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBLSPC_ERR]}"
				;;

				$GC_MSGT_HELP)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBLSPC_HELP]}"
				;;

				$GC_MSGT_INFO)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBLSPC_INFO]}"
				;;

				$GC_MSGT_SUCCESS)
					l_Prepend=""
				;;

				$GC_MSGT_USAGE)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBLSPC_USAGE]}"
				;;

				$GC_MSGT_WARN)
					l_Prepend="${GC_STR_ARY[$E_STR_MSG_LBLSPC_WARN]}"
				;;

				*)
					l_Prepend="INTERNAL ERROR"
				;;
			esac
		fi

		if [ $l_Idx -gt 0 ]; then						# If previous message
			l_ExitMsg+="\n"								# Add newline
		fi
		l_ExitMsg+="${l_Prepend}${l_MsgStr}."		# Add new message line/period to exit message
	done

	if [ ! -z "${l_ExitMsg}" ]; then					# If message
		l_ExitMsg+="\n"									# Add newline
	fi

	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*										Message Create And Print								 *
#*******************************************************************************
#
# Function: Creates message from message structures.
#
# Input:
#	Arg1	Global Variable Array name.
#	Arg2  Wine Manager error message array.
#	Arg3  Standard Script error message array.
#	Arg4	Token Parser error message array.
#
# Output:
#	No variables passed.
#
# Exit Status:
#	None.
#
function MsgCreateAndPrint()
{
	local -n l_GlblVarAry="$1"
	local -n l_ErrMsgAry="$2"
	local -n l_SsErrMsgAry="$3"
	local -n l_TpErrMsgAry="$4"
	local -a l_MsgPrint=""

	DbgPrint "${FUNCNAME[0]}: Entered."

	MsgCreate "${!l_GlblVarAry}" "${!l_ErrMsgAry}" "${!l_SsErrMsgAry}" "${!l_TpErrMsgAry}" l_MsgPrint
	MsgPrint "$l_MsgPrint"								# Print it
	
	DbgPrint "${FUNCNAME[0]}: Exiting."
	return $WM_ERR_NONE
}

#*******************************************************************************
#*                              Message Print Function                         *
#*******************************************************************************
#
# Function: Outputs exit message to stdout and system log.
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
function MsgPrint ()
{
   local l_ExitMsg="$1"									# Get message array
	if [ ! -z "$l_ExitMsg" ]; then					# If we have a message
		echo -e "$l_ExitMsg"								# Output message
																# If debug logging enabled
		if [ $DbgLog -eq 1 ] || [ $GlblDbgLog -eq 1 ]; then
																# Create log message
			ErrMsg="[$ThisPathNameUser] $l_ExitMsg"
			$LogCmd "$l_ExitMsg"							# Log error message
		fi
	fi
}

#*******************************************************************************
#*									Get Usage String for Command								 *
#*******************************************************************************
#
# Function: Gets usage string for command.
#
# Input: Arg1  Command.
#			Arg2  Return variable name (passed without $).
#			Arg3	Usage message array name.
#			Arg4	Help message array name.
#
# Output: Arg2 return variable contains usage message
#
function GetUsageStr ()
{
	local l_CmdStr="$1"
	local -n l_UsageStr="$2"
	local -n l_UsageAry="$3"
	local -n l_HelpAry="$4"

	DbgPrint "${FUNCNAME[0]}: Entered with command string \"$l_CmdStr\"."

	case "$l_CmdStr" in 
		"${GC_STR_ARY[$E_STR_CMD_APPEND]}")
			l_UsageStr="${l_UsageAry[$E_USG_APPEND]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_BACKUP]}")
			l_UsageStr="${l_UsageAry[$E_USG_BACKUP]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CHANGE]}")
			l_UsageStr="${l_UsageAry[$E_USG_CHANGE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CONF]}")
			l_UsageStr="${l_UsageAry[$E_USG_CONF]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CONSOLE]}")
			l_UsageStr="${l_UsageAry[$E_USG_CONSOLE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CREATE]}")
			l_UsageStr="${l_UsageAry[$E_USG_CREATE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_DEFAULT]}")
			l_UsageStr="${l_UsageAry[$E_USG_DEFAULT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_DEINIT]}")
			l_UsageStr="${l_UsageAry[$E_USG_DEINIT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_DELETE]}")
			l_UsageStr="${l_UsageAry[$E_USG_DELETE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_EDIT]}")
			l_UsageStr="${l_UsageAry[$E_USG_EDIT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_INIT]}")
			l_UsageStr="${l_UsageAry[$E_USG_INIT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_INSTANTIATE]}")
			l_UsageStr="${l_UsageAry[$E_USG_INSTANTIATE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_LIST]}")
			l_UsageStr="${l_UsageAry[$E_USG_LIST]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_XDG]}")
			l_UsageStr="${l_UsageAry[$E_USG_XDG]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_MIGRATE]}")
			l_UsageStr="${l_UsageAry[$E_USG_MIGRATE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_REFRESH]}")
			l_UsageStr="${l_UsageAry[$E_USG_REFRESH]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_RESTORE]}")
			l_UsageStr="${l_UsageAry[$E_USG_RESTORE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_HELP]}")
			l_UsageStr="${l_UsageAry[$E_USG_HELP]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_VERSION]}")
			l_UsageStr="${l_UsageAry[$E_USG_VERSION]}"
		;;

		*)
			DbgPrint "${FUNCNAME[0]}: Unrecognized command, loading G_HELP_ALL"

			l_UsageStr="${l_HelpAry[$E_HLP_ALL]}"
		;;
	esac

	DbgPrint "${FUNCNAME[0]}: Exiting."
}

#*******************************************************************************
#*										Get Help String for Command							 *
#*******************************************************************************
#
# Function: Gets help string for command.
#
# Input:	Arg1  Command.
#			Arg2  Return variable name (passed without $).
#			Arg3	Help message array name (passed without $).
#
# Output: Arg2 return variable contains help message
#
function GetHelpStr ()
{
	local l_CmdStr="$1"
	local -n l_HelpStr="$2"
	local -n l_HelpAry="$3"

	DbgPrint "${FUNCNAME[0]}: Entered with command string \"$l_CmdStr\"."

	case "$l_CmdStr" in 
		"${GC_STR_ARY[$E_STR_CMD_APPEND]}")
			l_HelpStr="${l_HelpAry[$E_HLP_APPEND]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_BACKUP]}")
			l_HelpStr="${l_HelpAry[$E_HLP_BACKUP]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CHANGE]}")
			l_HelpStr="${l_HelpAry[$E_HLP_CHANGE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CONF]}")
			l_HelpStr="${l_HelpAry[$E_HLP_CONF]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CONSOLE]}")
			l_HelpStr="${l_HelpAry[$E_HLP_CONSOLE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_CREATE]}")
			l_HelpStr="${l_HelpAry[$E_HLP_CREATE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_DEFAULT]}")
			l_HelpStr="${l_HelpAry[$E_HLP_DEFAULT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_DEINIT]}")
			l_HelpStr="${l_HelpAry[$E_HLP_DEINIT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_DELETE]}")
			l_HelpStr="${l_HelpAry[$E_HLP_DELETE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_EDIT]}")
			l_HelpStr="${l_HelpAry[$E_HLP_EDIT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_INIT]}")
			l_HelpStr="${l_HelpAry[$E_HLP_INIT]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_INSTANTIATE]}")
			l_HelpStr="${l_HelpAry[$E_HLP_INSTANTIATE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_LIST]}")
			l_HelpStr="${l_HelpAry[$E_HLP_LIST]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_XDG]}")
			l_HelpStr="${l_HelpAry[$E_HLP_XDG]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_MIGRATE]}")
			l_HelpStr="${l_HelpAry[$E_HLP_MIGRATE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_REFRESH]}")
			l_HelpStr="${l_HelpAry[$E_HLP_REFRESH]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_RESTORE]}")
			l_HelpStr="${l_HelpAry[$E_HLP_RESTORE]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_HELP]}")
			l_HelpStr="${l_HelpAry[$E_HLP_HELP]}"
		;;

		"${GC_STR_ARY[$E_STR_CMD_VERSION]}")
			l_HelpStr="${l_HelpAry[$E_HLP_VERSION]}"
		;;

		*)
			l_HelpStr="${l_HelpAry[$E_HLP_HELP]}"
		;;
	esac

	DbgPrint "${FUNCNAME[0]}: Exiting."
}

#*******************************************************************************
#*                                                                             *
#*													Main												 *
#*                                                                             *
#*******************************************************************************
. /usr/local/bin/standard_main.sh					# Standard main

# G_GLBL_VAR_ARY[$E_GLBL_VERBOSE]=0					# Set verbose flag (Make verbose command to do this later)

#
# ===================================
# Verify Global Environment Variables
# ===================================
#
#
WmVerifyEnvVars G_GLBL_VAR_ARY GC_ENV_VAR_ARY	# Verify environment variables
G_TMP_STAT=$?
if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then			# If error
	MsgCreateAndPrint G_GLBL_VAR_ARY GC_ERR_MSG_ARY GC_KF_ERR_MSG_ARY GC_TP_ERR_MSG_ARY
																# Exit with status
	CleanUpExit ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} ""
fi

#
# ======================================
# Special Instantiate Command Processing
# ======================================
#
																# If instantiate command
if [ "$1" == "${GC_STR_ARY[$E_STR_CMD_INSTANTIATE]}" ]; then
	G_TMP_INT=0												# Set force flag to no
	DbgPrint "Instantiate command dectected."
																# Get usage message
	GetUsageStr "${GC_STR_ARY[$E_STR_CMD_INSTANTIATE]}" G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE] GC_USAGE_ARY GC_HELP_ARY

# Argument Processing
# -------------------
	if [ "$#" -gt 2 ]; then								# If more than two arguments

		ErrAdd $WM_ERR_NUM_ARGS "Arguments: $#" G_GLBL_VAR_ARY
																# Load usage message
		MsgAdd $GC_MSGT_USAGE "${G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]}" G_GLBL_VAR_ARY
	
	elif [ "$#" -eq 2 ]; then							# If two arguments
																# If second arg is force
		if [ "$2" == "${GC_STR_ARY[$E_STR_TOKSTR_FORCE]}" ]; then
																# Verify dir destroy
			read -p "Any existing Wine Manager root data will be destroyed without further warning. Are you sure you want to force instantiation. (y/n)? " G_TMP_STR
			if [[ "$G_TMP_STR" == "y" || "$G_TMP_STR" == "Y" ]]; then
				DbgPrint "Instantiate force option dectected, setting force flag."
				G_TMP_INT=1									# Set force flag to yes
			else												# Otherwise it's an error
				ErrAdd $WM_ERR_DIR_EXISTS "Force instantiate command cancelled" G_GLBL_VAR_ARY
																# Load usage message
				MsgAdd $GC_MSGT_USAGE "${G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]}" G_GLBL_VAR_ARY
			fi
		else													# If not force option
			ErrAdd $WM_ERR_UNK_OPT "Option \"$2\"" G_GLBL_VAR_ARY
																# Load usage message
			MsgAdd $GC_MSGT_USAGE "${G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]}" G_GLBL_VAR_ARY
		fi
	fi
																# If no error
	if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
																# Try to instantiate
		WineManagerInstantiate $G_TMP_INT G_GLBL_VAR_ARY GC_STR_ARY GC_ROOT_DIR_ARY GC_BTL_DIR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
		G_TMP_STAT=$?
		if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then	# If no error
																# Load success message
			MsgAdd $GC_MSGT_SUCCESS "Wine Manager data directory \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\" Instantiation complete" G_GLBL_VAR_ARY
		else													# If error
																# Load usage message
			MsgAdd $GC_MSGT_USAGE "${G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]}" G_GLBL_VAR_ARY
		fi
	fi
																# Create and print exit message
	MsgCreateAndPrint G_GLBL_VAR_ARY GC_ERR_MSG_ARY GC_KF_ERR_MSG_ARY GC_TP_ERR_MSG_ARY
																# Exit with status
	CleanUpExit ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} ""
																# If no root directory
elif [ ! -e "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}" ]; then
	ErrAdd $WM_ERR_DIR_NEXIST "Wine Manager root directory \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\"" G_GLBL_VAR_ARY
																# Load usage message
	MsgAdd $GC_MSGT_USAGE "${G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]}" G_GLBL_VAR_ARY
																# Create and print exit message
	MsgCreateAndPrint G_GLBL_VAR_ARY GC_ERR_MSG_ARY GC_KF_ERR_MSG_ARY GC_TP_ERR_MSG_ARY
																# Exit with status
	CleanUpExit ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} ""
fi

#
# ==================================
# Verify Wine Manager Data Integrity
# ==================================
#
WmVerifyData G_GLBL_VAR_ARY GC_STR_ARY GC_ROOT_DIR_ARY GC_BTL_DIR_ARY
G_TMP_STAT="$?"											# Save exit status
DbgPrint "WmVerifyData exit status = \"$G_TMP_STAT\"."
																# Create and print message
MsgCreateAndPrint G_GLBL_VAR_ARY GC_ERR_MSG_ARY GC_KF_ERR_MSG_ARY  GC_TP_ERR_MSG_ARY
if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then			# If error
	G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]=$G_TMP_STAT	# Set exit stat
	CleanUpExit ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} ""
fi

#
# =========================
# Process Command Arguments
# =========================
#
# Note: We prepend "${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" to the users input argument array and associate it with G_TOK_VAR_ARY[$E_TOK_CMD] so the
# token parser returns the first string entered as the command.
#
																# Parse input command string
G_INPUT_ARY=("${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" "$@")
TokParse G_INPUT_ARY G_TOK_ARY G_TOK_VAR_ARY[$E_TOK_NUM_TOKS] G_TOK_VAR_ARY[$E_TOK_LAST_II] G_TOK_VAR_ARY[$E_TOK_LAST_PI] G_TOK_VAR_ARY[$E_TOK_LAST_AI]
G_TMP_STAT=$?
DbgPrint "Token Parser exit status = \"$G_TMP_STAT\"."
if [ $G_TMP_STAT -ne $TP_ERR_NONE ]; then			# If parse error
	DbgPrint "Doing generic Token Parser error message processing with status \"$G_TMP_STAT\"."
																# Do generic extra error message processing
	TokParse_StatDecode $G_TMP_STAT G_INPUT_ARY G_TOK_ARY "${G_TOK_VAR_ARY[$E_TOK_LAST_II]}" "${G_TOK_VAR_ARY[$E_TOK_LAST_PI]}" "${G_TOK_VAR_ARY[$E_TOK_LAST_AI]}" G_TMP_STR
	ErrAdd $(($WM_ERR_TOTAL+$GC_KF_ERR_TOTAL+$G_TMP_STAT)) "$G_TMP_STR" G_GLBL_VAR_ARY
																# Load help message
	MsgAdd $GC_MSGT_HELP "\n${GC_HELP_ARY[$E_HLP_ALL]}" G_GLBL_VAR_ARY
																# Create and print exit message
	MsgCreateAndPrint G_GLBL_VAR_ARY GC_ERR_MSG_ARY GC_KF_ERR_MSG_ARY GC_TP_ERR_MSG_ARY
																# Exit with failed status
	CleanUpExit ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} ""
fi

TokParse_SpcClr G_TOK_ARY								# Clear space only args
																# If we got a command
if [ ${G_TOK_VAR_ARY[$E_TOK_CMDF]} -eq 1 ] && [ ! -z "${G_TOK_VAR_ARY[$E_TOK_CMD]}" ]; then
	DbgPrint "Command \"${G_TOK_VAR_ARY[$E_TOK_CMD]}\" found, getting usage and help commands."
																# Get usage string for command
	GetUsageStr "${G_TOK_VAR_ARY[$E_TOK_CMD]}" G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE] GC_USAGE_ARY GC_HELP_ARY
																# Get help string for command
	GetHelpStr "${G_TOK_VAR_ARY[$E_TOK_CMD]}" G_GLBL_VAR_ARY[$E_GLBL_STR_HELP] GC_HELP_ARY
else															# If no command
	ErrAdd $WM_ERR_NO_CMD "" G_GLBL_VAR_ARY
																# Load help message
	MsgAdd $GC_MSGT_HELP "\n${GC_HELP_ARY[$E_HLP_ALL]}" G_GLBL_VAR_ARY
																# Create and print exit message
	MsgCreateAndPrint G_GLBL_VAR_ARY GC_ERR_MSG_ARY GC_KF_ERR_MSG_ARY GC_TP_ERR_MSG_ARY
																# Exit with failed status
	CleanUpExit ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} ""
fi 

#
# ================
# Process Commands
# ================
#
case "${G_TOK_VAR_ARY[$E_TOK_CMD]}" in
#
# --------------
# Append Command
# --------------
#
"${GC_STR_ARY[$E_STR_CMD_APPEND]}")
	DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_APPEND]}: Processing."
																# Parse arguments
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} ${GC_STR_ARY[$E_STR_TOKSTR_VAL]}" "${GC_STR_ARY[$E_STR_TOKSTR_SUB_DIR]}" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# Check arguments, bottle existence, not XDG or default
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY && IsNotXdgDefaultSys "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
		G_TMP_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"
		G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
		DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_APPEND]}: Bottle = \"$G_TMP_BTL_NAME\", Pathname = \"$G_TMP_BTL_PATHNAME\"."
																# Create dir head path
		G_TMP_DIR_NAME="$G_TMP_BTL_PATHNAME/${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}"
		G_TMP_ARY=()										# Clear dir array
																# Get append value
		G_TMP_STR="${G_TOK_VAR_ARY[$E_TOK_VAL]}"
		G_TMP_FLAG=0										# Clear dir processed flag
																# If subdirectory specified
		if [ ${G_TOK_VAR_ARY[$E_TOK_SUB_DIRF]} -eq 1 ]; then
																# Create single dir array
			G_TMP_ARY=( "$G_TMP_DIR_NAME/${G_TOK_VAR_ARY[$E_TOK_SUB_DIR]}" )
			DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_APPEND]}: Added \"$G_TMP_DIR_NAME/${G_TOK_VAR_ARY[$E_TOK_SUB_DIR]}\" to single directory array."
		else													# Else get directory subpath for desktop files
			for G_TMP_SUBDIR in "${GC_XDG_DSKTP_SUBPATH_ARY[@]}"
			do													# Add dir to array
				G_TMP_ARY+=( "$G_TMP_DIR_NAME/$G_TMP_SUBDIR" )
				DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_APPEND]}: Added \"$G_TMP_DIR_NAME/$G_TMP_SUBDIR\" to multiple directory array."
			done
		fi
																# Process all directories
		for G_TMP_DIR_NAME in "${G_TMP_ARY[@]}"
		do
			if [ -e "$G_TMP_DIR_NAME" ]; then		# If dir exists
				G_TMP_FLAG=1								# Set dir processed flag
				cd "$G_TMP_DIR_NAME"						# Change to it
																# Process all .desktop files
				find . -print | grep -i '.desktop' | while read G_TMP_FILE_NAME
				do
					DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_APPEND]}: Appending \"$G_TMP_STR\" to desktop file '$G_TMP_FILE_NAME'."
					sed -i '/^Exec=/s#\([^"]*\)"$#\1 '"$G_TMP_STR"'"#' "$G_TMP_FILE_NAME"
				done
			else												# If dir doesn't exist
				DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_APPEND]}: Directory \"$G_TMP_DIR_NAME\" doesn't exist, skipping."
				MsgAdd $GC_MSGT_WARN "Directory \"$G_TMP_DIR_NAME\" doesn't exist, skipping" G_GLBL_VAR_ARY
			fi
		done

		if [ $G_TMP_FLAG -eq 1 ]; then
			MsgAdd $GC_MSGT_SUCCESS "Wine bottle \"$G_TMP_BTL_NAME\" Exec append successfully completed" G_GLBL_VAR_ARY
		else
			MsgAdd $GC_MSGT_WARN "No directories processed for Wine bottle \"$G_TMP_BTL_NAME\"" G_GLBL_VAR_ARY
		fi
	fi

	DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_APPEND]}: Exiting"
	;;

#
# --------------
# Backup Command
# --------------
#
"${GC_STR_ARY[$E_STR_CMD_BACKUP]}")
	DbgPrint "COMMAND backup: Processing command"
																# Parse arguments
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# Check arguments, bottle existence, not XDG or default
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY && IsNotXdgDefaultSys "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
		G_TMP_FLAG=0										# Clear cancel flag
																# Get bottle name/pathname
		G_TMP_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"
		G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
		DbgPrint "COMMAND backup: Bottle = \"$G_TMP_BTL_NAME\", Pathname = \"$G_TMP_BTL_PATHNAME\"."
																# Create backup bottle pathname
		G_TMP_WRK_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_BCKP_DIR]}/$G_TMP_BTL_NAME"

		if [ -e "$G_TMP_WRK_BTL_PATHNAME" ]; then	# If backup bottle exists
			read -p "Are you sure you want to overwrite backup bottle \"$G_TMP_WRK_BTL_PATHNAME\" (y/n)? " G_TMP_STR
			case "$G_TMP_STR" in 
				y|Y)											# Yes
					DbgPrint "Deleting backup bottle \"$G_TMP_WRK_BTL_PATHNAME\""
																# Delete backup bottle
					echo "Deleting old backup bottle \"$G_TMP_WRK_BTL_PATHNAME\" ..."
					rm -rf "$G_TMP_WRK_BTL_PATHNAME" >/dev/null 2>&1
					G_TMP_STAT=$?
					if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
																# Load error info if fail
						ErrAdd $WM_ERR_DIR_DEL "Backup bottle delete failed with exit status \"$G_TMP_STAT\"" G_GLBL_VAR_ARY
					else
						echo "Old backup bottle \"$G_TMP_WRK_BTL_PATHNAME\" deleted."
					fi
				;;

				n|N)											# No
					MsgAdd $GC_MSGT_SUCCESS "Backup for bottle \"$G_TMP_BTL_NAME\" cancelled" G_GLBL_VAR_ARY
					G_TMP_FLAG=1							# Set cancel flag
				;;

				*)												# Load error info if invalid response from AskYesNo
					ErrAdd $WM_ERR_INV_RESP "Response: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
				;;
			esac
		fi
																# If no error or cancel
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && $G_TMP_FLAG -ne 1 ]]; then
																# Unmount bottle
			BottleUnmount "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY
			G_TMP_STAT=$?									# Save status
																# If fail
			if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
				MsgAdd $GC_MSGT_ERR "Bottle \"$G_TMP_BTL_NAME\" unmount failed" G_GLBL_VAR_ARY
			else
																# Copy bottle to backup
				echo -e "Backing up Wine bottle \"$G_TMP_BTL_PATHNAME\" to \"$G_TMP_WRK_BTL_PATHNAME\" ..."
				cp -r "$G_TMP_BTL_PATHNAME" "$G_TMP_WRK_BTL_PATHNAME" >/dev/null 2>&1
				G_TMP_STAT=$?								# If copy failed
				if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
																# Load error info if fail
					ErrAdd $WM_ERR_FILE_COPY "Bottle \"$G_TMP_BTL_PATHNAME\" copy to backup bottle \"$G_TMP_WRK_BTL_PATHNAME\" failed with status \"$G_TMP_STAT\"" G_GLBL_VAR_ARY
				else
																# Remount bottle
					BottleMount "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
					G_TMP_STAT=$?							# Save status
																# If fail
					if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
						MsgAdd $GC_MSGT_ERR "Bottle \"$G_TMP_BTL_NAME\" mount failed" G_GLBL_VAR_ARY
					else
						MsgAdd $GC_MSGT_SUCCESS "Bottle \"$G_TMP_BTL_PATHNAME\" backed up to \"$G_TMP_WRK_BTL_PATHNAME\"" G_GLBL_VAR_ARY
					fi
				fi
			fi
		fi
	fi
	DbgPrint "COMMAND backup: Exiting"
	;;

#
# --------------
# Change Command
# --------------
#
"${GC_STR_ARY[$E_STR_CMD_CHANGE]}")
	DbgPrint "COMMAND change: Processing"
																# Parse arguments
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "${GC_STR_ARY[$E_STR_TOKSTR_NAME]} ${GC_STR_ARY[$E_STR_TOKSTR_WINE_VER]} ${GC_STR_ARY[$E_STR_TOKSTR_ENV]} ${GC_STR_ARY[$E_STR_TOKSTR_SUBMENU]}" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# Check arguments, bottle existence, not XDG or default
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY && IsNotXdgDefaultSys "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
		G_TMP_FLAG=0										# Clear bottle unmounted flag
																# Get bottle name/pathname/conf file
		G_TMP_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"
		G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
		G_TMP_BTL_CONF_FILE="$G_TMP_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}"
																# If nothing to change
		if [ ${G_TOK_VAR_ARY[$E_TOK_ENVF]} -eq 0 ] && [ ${G_TOK_VAR_ARY[$E_TOK_SUBMENUF]} -eq 0 ] && [ ${G_TOK_VAR_ARY[$E_TOK_WINE_VERF]} -eq 0 ] && [ ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 0 ]; then
			ErrAdd $WM_ERR_PARM_MISS "No options to change" G_GLBL_VAR_ARY
		else
			BottleUnmount "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY
			G_TMP_STAT=$?
																# If fail
			if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
				MsgAdd $GC_MSGT_ERR "Bottle \"$G_TMP_BTL_NAME\" unmount failed" G_GLBL_VAR_ARY
			else
				G_TMP_FLAG=1								# Else set bottle unmounted flag
			fi
		fi

# Change Bottle Name
# ------------------
																# If no error and new bottle name
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 1 ]]; then
			DbgPrint "COMMAND change: Change bottle name detected"
																# If new bottle name null
			if [ -z "${G_TOK_VAR_ARY[$E_TOK_NAME]}" ]; then
				ErrAdd $WM_ERR_BTL_NNAME "" G_GLBL_VAR_ARY
			else												# If not null
																# Create new bottle name/pathname
				G_TMP_WRK_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_NAME]}"
				G_TMP_WRK_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_WRK_BTL_NAME"
																# If bottle already exists
				if [ -e "$G_TMP_WRK_BTL_PATHNAME" ]; then
					ErrAdd $WM_ERR_BTL_EXISTS "Bottle: \"$G_TMP_WRK_BTL_PATHNAME\"" G_GLBL_VAR_ARY
				else
																# Get directory subpath for desktop files
					for G_TMP_DIR_NAME in "${GC_XDG_DSKTP_SUBPATH_ARY[@]}"
					do
						DbgPrint "COMMAND change: Changing name into all bottle \"$G_TMP_BTL_NAME\" .desktop files"
																# Change to desktop directory
						cd "$G_TMP_BTL_PATHNAME/${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}/$G_TMP_DIR_NAME"
																# Process all .desktop files
						find . -print | grep -i '.desktop' | while read G_TMP_FILE_NAME
						do
							DbgPrint "COMMAND change: Processing desktop file '$G_TMP_FILE_NAME'."
							sed -i 's#'"$G_TMP_BTL_NAME"'#'"$G_TMP_WRK_BTL_NAME"'#g' "$G_TMP_FILE_NAME"
						done
					done
																# Get current env file 
					KeyRd "${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}" "G_TMP_BTL_ENV_FILE" "$G_TMP_BTL_CONF_FILE"
					G_TMP_STAT=$?
																# If read fail return Standard Script error code
					if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
						ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "change${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$G_TMP_BTL_CONF_FILE\"" G_GLBL_VAR_ARY
																# If we have an environment file
					elif [ ! -z "$G_TMP_BTL_ENV_FILE" ]; then
																# If environment file exists
						if [ -e "$G_TMP_BTL_ENV_FILE" ]; then
																# Change bottle name
							sed -i 's#'"$G_TMP_BTL_NAME"'#'"$G_TMP_WRK_BTL_NAME"'#g' "$G_TMP_BTL_ENV_FILE"
						fi
																# Create new environment file pathname
						G_TMP_BTL_ENV_FILE="$G_TMP_WRK_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_BIN_DIR]}/${GC_STR_ARY[$E_STR_BTL_ENV_FILE_NAME]}"
																# Write new env file pathname
						KeyWr "${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}" "$G_TMP_BTL_ENV_FILE" "$G_TMP_BTL_CONF_FILE"
						G_TMP_STAT=$?
																# If write failed
						if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
							DbgPrint "COMMAND change: Write key failed with status = \"$G_TMP_STAT\"."
																# If fail create Standard Script error code
							ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "change${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}\", File = \"${GC_STR_ARY[$E_STR_WM_CONF_FILE]}\"" G_GLBL_VAR_ARY
						fi
					fi
				fi
																# If no error
				if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]]; then
																# Change bottle name
					mv "$G_TMP_BTL_PATHNAME" "$G_TMP_WRK_BTL_PATHNAME" >/dev/null 2>&1
					G_TMP_STAT=$?
																# If rename failed
					if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
						DbgPrint "Bottle rename failed with status = \"$G_TMP_STAT\"."
						ErrAdd $WM_ERR_BTL_RENAME "change${GC_SEP_FTRC} Bottle = \"$G_TMP_BTL_PATHNAME\"" G_GLBL_VAR_ARY
					else										# If rename succeeded
						MsgAdd $GC_MSGT_INFO "Bottle \"$G_TMP_BTL_NAME\" name changed to \"$G_TMP_WRK_BTL_NAME\"" G_GLBL_VAR_ARY
																# Delete old bottle name wine menu
						BottleWmMenuDel "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY
																# Set new bottle name/pathname/conf file
						G_TMP_BTL_NAME="$G_TMP_WRK_BTL_NAME"
						G_TMP_BTL_PATHNAME="$G_TMP_WRK_BTL_PATHNAME"
						G_TMP_BTL_CONF_FILE="$G_TMP_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}"
																# Add new bottle name wine menu
						BottleWmMenuAdd "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY
					fi
				fi
			fi
		fi
#
# Change Bottle Wine Directory
# ----------------------------
																# If no error and new wine version
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ${G_TOK_VAR_ARY[$E_TOK_WINE_VERF]} -eq 1 ]]; then
			DbgPrint "COMMAND change: Change bottle wine version detected"
																# Get current wine version 
			KeyRd "${GC_STR_ARY[$E_STR_KEY_BTL_WINEDIR]}" "G_TMP_WINEDIR_NAME" "$G_TMP_BTL_CONF_FILE"
			G_TMP_STAT=$?
																# If read fail return Standard Script error code
			if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
				ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "change${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_WINEDIR]}\", File = \"$G_TMP_BTL_CONF_FILE\"" G_GLBL_VAR_ARY
			else
				DbgPrint "COMMAND change: Current wine version is \"$G_TMP_WINEDIR_NAME\""
																# Get new wine dir without trailing slash
				G_TMP_DIR_NAME="$(echo "${G_TOK_VAR_ARY[$E_TOK_WINE_VER]}" | sed 's#/$##')"
				DbgPrint "COMMAND change: Change wine version is \"$G_TMP_DIR_NAME\""
				if [ -z "$G_TMP_DIR_NAME" ]; then	# If changing to default
					G_TMP_EXEC_NAME="wine"				# Exec is "wine"
				else											# Else get new wine exec
					G_TMP_EXEC_NAME="$G_TMP_DIR_NAME/bin/wine"
				fi

				DbgPrint "Change wine executable is \"$G_TMP_EXEC_NAME\""
																# Check if wine exec exists
				which "$G_TMP_EXEC_NAME" >/dev/null 2>&1
				G_TMP_STAT=$?
																# If not return error status
				if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
					ErrAdd $WM_ERR_FILE_NEXEC "change${GC_SEP_FTRC}Wine Executable = \"$G_TMP_EXEC_NAME\"" G_GLBL_VAR_ARY
				else
																# If same version as now
					if [ "$G_TMP_WINEDIR_NAME" == "$G_TMP_DIR_NAME" ]; then
						if [ ! -z "$G_TMP_DIR_NAME" ]; then
							MsgAdd $GC_MSGT_WARN "Bottle \"$G_TMP_BTL_NAME\" already uses wine version \"$G_TMP_DIR_NAME\", not changing" G_GLBL_VAR_ARY
						else
							MsgAdd $GC_MSGT_WARN "Bottle \"$G_TMP_BTL_NAME\" already uses system default wine, not changing" G_GLBL_VAR_ARY
						fi
					else
																# Write new wine version to conf
						KeyWr "${GC_STR_ARY[$E_STR_KEY_BTL_WINEDIR]}" "$G_TMP_DIR_NAME" "$G_TMP_BTL_CONF_FILE"
						G_TMP_STAT=$?
																# If write failed
						if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
							DbgPrint "COMMAND change: Write key failed with status = \"$G_TMP_STAT\"."
																# If fail create Standard Script error code
							ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "change${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_WINEDIR]}\", File = \"${GC_STR_ARY[$E_STR_WM_CONF_FILE]}\"" G_GLBL_VAR_ARY
						else
																# Get current env file 
							KeyRd "${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}" "G_TMP_BTL_ENV_FILE" "$G_TMP_BTL_CONF_FILE"
							G_TMP_STAT=$?
																# If read fail return Standard Script error code
							if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
								ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "change${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$G_TMP_BTL_CONF_FILE\"" G_GLBL_VAR_ARY
							else
																# If we have an environment file
								if [ ! -z "$G_TMP_BTL_ENV_FILE" ]; then
																# If environment file exists
									if [ -e "$G_TMP_BTL_ENV_FILE" ]; then
																# Change wine version
										sed -i 's#'"$G_TMP_WINEDIR_NAME"'#'"$G_TMP_DIR_NAME"'#g' "$G_TMP_BTL_ENV_FILE"
									fi
								fi
																# Set new wine dir
								G_TMP_WINEDIR_NAME="$G_TMP_DIR_NAME"
																# Change exec in all desktop files
								ChangeWineExecBottle "$G_TMP_BTL_PATHNAME" "$G_TMP_EXEC_NAME" GC_XDG_DIR_ARY GC_XDG_DSKTP_SUBPATH_ARY

								if [ ! -z "$G_TMP_WINEDIR_NAME" ]; then
									MsgAdd $GC_MSGT_INFO "Bottle \"$G_TMP_BTL_NAME\" wine version changed to \"$G_TMP_WINEDIR_NAME\"" G_GLBL_VAR_ARY
								else
									MsgAdd $GC_MSGT_INFO "Bottle \"$G_TMP_BTL_NAME\" wine version changed to default" G_GLBL_VAR_ARY
								fi
							fi
						fi
					fi
				fi
			fi
		fi
#
# Change Bottle Environment File
# ------------------------------
																# If no error and new environment
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ${G_TOK_VAR_ARY[$E_TOK_ENVF]} -eq 1 ]]; then
			DbgPrint "COMMAND change: Change bottle environment detected"
			G_TMP_BTL_ENV_FILE="${G_TOK_VAR_ARY[$E_TOK_ENV]}"
			BottleEnvCreate "$G_TMP_BTL_NAME" "$G_TMP_BTL_ENV_FILE" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_DSKTP_SUBPATH_ARY
			G_TMP_STAT=$?
			if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
				MsgPrepend "change${GC_SEP_FTRC}" G_GLBL_VAR_ARY
			else
				MsgAdd $GC_MSGT_INFO "Bottle \"$G_TMP_BTL_NAME\" environment changed successfully" G_GLBL_VAR_ARY
			fi
		fi

#
# Change Bottle Sub Menu
# ----------------------
																# If no error and new submenu
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ${G_TOK_VAR_ARY[$E_TOK_SUBMENUF]} -eq 1 ]]; then
			DbgPrint "COMMAND change: Change bottle submenu detected"
																# Get submenu
			G_TMP_STR="${G_TOK_VAR_ARY[$E_TOK_SUBMENU]}"
																# Write submenu to conf
			KeyWr "${GC_STR_ARY[$E_STR_KEY_BTL_SMENU]}" "$G_TMP_STR" "$G_TMP_BTL_CONF_FILE"
			G_TMP_STAT=$?
			if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
				ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "change${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_SMENU]}\", Value = \"$G_TMP_STR\", File = \"$G_TMP_BTL_CONF_FILE\"" G_GLBL_VAR_ARY
			else	
				if [ ! -z "$G_TMP_STR" ]; then
					MsgAdd $GC_MSGT_INFO "Bottle \"$G_TMP_BTL_NAME\" submenu changed to \"$G_TMP_STR\"" G_GLBL_VAR_ARY
				else
					MsgAdd $GC_MSGT_INFO "Bottle \"$G_TMP_BTL_NAME\" submenu deleted" G_GLBL_VAR_ARY
				fi
			fi
		fi
#
# Exit Processing
# ---------------
		if [ $G_TMP_FLAG -eq 1 ]; then				# If bottle was unmounted 
																# Try to remount bottle
			BottleMount "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
			G_TMP_STAT=$?									# If fail
			if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
																# Add mount error
				MsgAdd $GC_MSGT_ERR "Bottle \"$G_TMP_BTL_NAME\" mount failed with Status = \"$G_TMP_STAT\"" G_GLBL_VAR_ARY
			fi
		fi
																# If no error
		if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
			MsgAdd $GC_MSGT_SUCCESS "Bottle \"$G_TMP_BTL_NAME\" changes completed successfully" G_GLBL_VAR_ARY
		fi
	fi
	DbgPrint "COMMAND change: Exiting"
	;;

#
# -----------------
# Configure Command
# -----------------
#
"${GC_STR_ARY[$E_STR_CMD_CONF]}")
	DbgPrint "COMMAND conf: Processing configure Windows Manager or bottle command."
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_MODE]} ${GC_STR_ARY[$E_STR_TOKSTR_OPT]}" "${GC_STR_ARY[$E_STR_TOKSTR_NAME]} ${GC_STR_ARY[$E_STR_TOKSTR_VAL]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY; then

		G_TMP_STAT=0										# Set Exit Request Flag to no

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Verify Valid Option Arguments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		case "${G_TOK_VAR_ARY[$E_TOK_MODE]}" in 
			"${GC_STR_ARY[$E_STR_CMD_ARG_BOTTLE]}")	# If bottle mode
# Bottle -
# RD,DEL: Bottle, Name
# WR: Bottle, Name, Value
# HELP: Nothing
#
				case "${G_TOK_VAR_ARY[$E_TOK_OPT]}" in 
					"${GC_STR_ARY[$E_STR_CMD_ARG_RD]}"|"${GC_STR_ARY[$E_STR_CMD_ARG_DEL]}")
																# If no bottle or var name
						if [[ ${G_TOK_VAR_ARY[$E_TOK_BTLF]} -eq 0 || ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 0 ]]; then
							ErrAdd $WM_ERR_PARM_MISS "Bottle and variable names are required" G_GLBL_VAR_ARY
																# If var value
						elif [ ${G_TOK_VAR_ARY[$E_TOK_VALF]} -eq 1 ]; then
							ErrAdd $WM_ERR_PARM_INV "Variable value is not used for this command" G_GLBL_VAR_ARY
						fi
					;;

					"${GC_STR_ARY[$E_STR_CMD_ARG_WR]}")
																# If no bottle or var name, or value
						if [[ ${G_TOK_VAR_ARY[$E_TOK_BTLF]} -eq 0 || ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 0 || ${G_TOK_VAR_ARY[$E_TOK_VALF]} -eq 0 ]]; then
							ErrAdd $WM_ERR_PARM_MISS "Bottle name, and variable name and value are required" G_GLBL_VAR_ARY
						fi
					;;

					"${GC_STR_ARY[$E_STR_CMD_ARG_HELP]}")
																# If bottle or var name, or value
						if [[ ${G_TOK_VAR_ARY[$E_TOK_BTLF]} -eq 1 || ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 1 || ${G_TOK_VAR_ARY[$E_TOK_VALF]} -eq 1 ]]; then
							ErrAdd $WM_ERR_PARM_INV "Bottle name, and variable name and value are not used for this command" G_GLBL_VAR_ARY
						fi
					;;

					*)												# Unrecognized option
						ErrAdd $WM_ERR_UNK_ARG "Argument: Option \"${G_TOK_VAR_ARY[$E_TOK_OPT]}\"" G_GLBL_VAR_ARY
					;;
				esac
			;;

			"${GC_STR_ARY[$E_STR_CMD_ARG_MANAGER]}")	# If wine manager mode
# Manager -
# RD,DEL: Name
# WR: Name, Value
# HELP: Nothing
				case "${G_TOK_VAR_ARY[$E_TOK_OPT]}" in 
					"${GC_STR_ARY[$E_STR_CMD_ARG_RD]}"|"${GC_STR_ARY[$E_STR_CMD_ARG_DEL]}")
																# If no var name
						if [ ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 0 ]; then
							ErrAdd $WM_ERR_PARM_MISS "Variable name is required" G_GLBL_VAR_ARY
																# If bottle name or var value
						elif [[ ${G_TOK_VAR_ARY[$E_TOK_BTLF]} -eq 1 || ${G_TOK_VAR_ARY[$E_TOK_VALF]} -eq 1 ]]; then
							ErrAdd $WM_ERR_PARM_INV "Bottle name and variable value are not used for this command" G_GLBL_VAR_ARY
						fi
					;;

					"${GC_STR_ARY[$E_STR_CMD_ARG_WR]}")
																# If no var name or value
						if [[ ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 0 || ${G_TOK_VAR_ARY[$E_TOK_VALF]} -eq 0 ]]; then
							ErrAdd $WM_ERR_PARM_MISS "Variable name and value are required" G_GLBL_VAR_ARY
						elif [ ${G_TOK_VAR_ARY[$E_TOK_BTLF]} -eq 1 ]; then
							ErrAdd $WM_ERR_PARM_INV "Bottle name is not used for this command" G_GLBL_VAR_ARY
						fi

					;;

					"${GC_STR_ARY[$E_STR_CMD_ARG_HELP]}")
																# If bottle or var name, or value
						if [[ ${G_TOK_VAR_ARY[$E_TOK_BTLF]} -eq 1 || ${G_TOK_VAR_ARY[$E_TOK_NAMEF]} -eq 1 || ${G_TOK_VAR_ARY[$E_TOK_VALF]} -eq 1 ]]; then
						ErrAdd $WM_ERR_PARM_INV "Bottle name, and variable name and value are not used for this command" G_GLBL_VAR_ARY
						fi
					;;

					*)												# Unrecognized option
						ErrAdd $WM_ERR_UNK_ARG "Argument: Option \"${G_TOK_VAR_ARY[$E_TOK_OPT]}\"" G_GLBL_VAR_ARY
					;;
				esac
			;;

			*)													# Unrecognized mode
				ErrAdd $WM_ERR_UNK_ARG "Argument: Mode \"${G_TOK_VAR_ARY[$E_TOK_MODE]}\"" G_GLBL_VAR_ARY
			;;
		esac

# ~~~~~~~~~~~~~~~~~~~~
# Wildcard Error Check
# ~~~~~~~~~~~~~~~~~~~~
																# If no error
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]]; then
																# If null var name but not read
			if [[ -z "${G_TOK_VAR_ARY[$E_TOK_NAME]}" && "${G_TOK_VAR_ARY[$E_TOK_OPT]}" != "${GC_STR_ARY[$E_STR_CMD_ARG_RD]}" ]]; then
				ErrAdd $WM_ERR_PARM_INV "Variable name wildcard is not allowed for this command" G_GLBL_VAR_ARY
			fi
		fi

# ~~~~~~~~~~~~~~~~
# Process Commands
# ~~~~~~~~~~~~~~~~
																# If no error
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]]; then

			case "${G_TOK_VAR_ARY[$E_TOK_MODE]}" in 

# -----------
# Bottle Mode
# -----------
																# If bottle mode
				"${GC_STR_ARY[$E_STR_CMD_ARG_BOTTLE]}")

					G_TMP_STAT=0							# Clear exit request
																# If not help command create bottle array
					if [[ "${G_TOK_VAR_ARY[$E_TOK_OPT]}" != "${GC_STR_ARY[$E_STR_CMD_ARG_HELP]}" ]]; then
																# If single bottle
						if [ ! -z "${G_TOK_VAR_ARY[$E_TOK_BTL]}" ]; then
							DbgPrint "COMMAND conf: Creating one bottle array."
																# If bottle exists
							BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY
							G_TMP_STAT=$?
							if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# Create one bottle array
								G_TMP_ARY=( "${G_TOK_VAR_ARY[$E_TOK_BTL]}" )
							else
								G_TMP_ARY=( )				# If it doesn't clear array
								G_TMP_STAT=1				# Set exit request
							fi
						else									# If all bottles
							DbgPrint "COMMAND conf: Creating all bottles array."
																# Create all bottle array
							G_TMP_ARY=( `ls -1 -I "*.${GC_STR_ARY[$E_STR_WM_SYS_EXT]}" "${GC_STR_ARY[$E_STR_WM_BTL_DIR]}"` )
																# If no bottles
							if [ ${#G_TMP_ARY[@]} -eq 0 ]; then
																# Set success message
								MsgAdd $GC_MSGT_SUCCESS "There are no bottles, can't set bottle variable" G_GLBL_VAR_ARY
								G_TMP_STAT=1				# Set exit request
							fi
						fi
					fi

					if [[ $G_TMP_STAT -ne 1 ]]; then	# If no exit request
																# Process by option
						case "${G_TOK_VAR_ARY[$E_TOK_OPT]}" in 

# Bottle Configuration Read
# -------------------------
							"${GC_STR_ARY[$E_STR_CMD_ARG_RD]}")
								ConfVarList "${G_TOK_VAR_ARY[$E_TOK_NAME]}" GC_CVAR_BTLP_ARY GC_CVAR_BTLW_ARY G_GLBL_VAR_ARY GC_STR_ARY G_TMP_ARY
							;;

# Bottle Configuration Write
# --------------------------
							"${GC_STR_ARY[$E_STR_CMD_ARG_WR]}")
																# If variable and value okay
								if VarValChk "${G_TOK_VAR_ARY[$E_TOK_NAME]}" "${G_TOK_VAR_ARY[$E_TOK_VAL]}" GC_CVAR_BTLP_ARY GC_CVAR_BTLW_ARY G_TMP_INT G_GLBL_VAR_ARY; then
																# If protected variable
									if [ $G_TMP_INT -eq $GC_FUNCS_VarTypeChk_P ]; then
										ErrAdd $WM_ERR_CVAR_WR "\"${G_TOK_VAR_ARY[$E_TOK_NAME]}\" is a Protected Bottle Variable, it cannot be written" G_GLBL_VAR_ARY
									else
										for G_TMP_BTL_NAME in "${G_TMP_ARY[@]}";
										do
																# Create full bottle pathname
											G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
											DbgPrint "COMMAND conf: Bottle pathanme = \"$G_TMP_BTL_PATHNAME\"."
																# Create bottle conf file name
											G_TMP_CONF_PATHNAME="$G_TMP_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}"
											DbgPrint "COMMAND conf: Bottle conf file pathanme = \"$G_TMP_CONF_PATHNAME\"."
																# Write new variable value
											KeyAddWr "${G_TOK_VAR_ARY[$E_TOK_NAME]}" "${G_TOK_VAR_ARY[$E_TOK_VAL]}" "$G_TMP_CONF_PATHNAME"
											l_RetStat=$?
											if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
												ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "COMMAND conf${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${G_TOK_VAR_ARY[$E_TOK_NAME]}\", Value = \"${G_TOK_VAR_ARY[$E_TOK_VAL]}\", File = \"$G_TMP_CONF_PATHNAME\"" G_GLBL_VAR_ARY
												break
											fi
										done
										ConfVarList "${G_TOK_VAR_ARY[$E_TOK_NAME]}" GC_CVAR_BTLP_ARY GC_CVAR_BTLW_ARY G_GLBL_VAR_ARY GC_STR_ARY G_TMP_ARY
									fi
								fi
							;;

# Bottle Configuration Delete
# ---------------------------
							"${GC_STR_ARY[$E_STR_CMD_ARG_DEL]}")
																# Get variable type
								VarTypeChk "${G_TOK_VAR_ARY[$E_TOK_NAME]}" GC_CVAR_BTLP_ARY GC_CVAR_BTLW_ARY G_GLBL_VAR_ARY
																# If protected variable
								if [ $? -eq $GC_FUNCS_VarTypeChk_P ]; then
									ErrAdd $WM_ERR_CVAR_DEL "\"${G_TOK_VAR_ARY[$E_TOK_NAME]}\" is a Protected Bottle Variable" G_GLBL_VAR_ARY
								else
									for G_TMP_BTL_NAME in "${G_TMP_ARY[@]}";
									do
																# Create full bottle pathname
										G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
										DbgPrint "COMMAND conf: Bottle pathanme = \"$G_TMP_BTL_PATHNAME\"."
																# Create bottle conf file name
										G_TMP_CONF_PATHNAME="$G_TMP_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}"
										DbgPrint "COMMAND conf: Bottle conf file pathanme = \"$G_TMP_CONF_PATHNAME\"."
																# Delete variable value
										KeyDel "${G_TOK_VAR_ARY[$E_TOK_NAME]}" "$G_TMP_CONF_PATHNAME"
										l_RetStat=$?
																# If it exists
										if [ $l_RetStat -eq $GC_KF_ERR_NONE ];then
											MsgAdd $GC_MSGT_INFO "DELETED FROM: \"$G_TMP_BTL_NAME\"" G_GLBL_VAR_ARY
										else					# If it doesn't exist
											MsgAdd $GC_MSGT_INFO "      NOT IN: \"$G_TMP_BTL_NAME\"" G_GLBL_VAR_ARY
										fi
									done
								fi
							;;

# Bottle Configuration Help
# -------------------------
							"${GC_STR_ARY[$E_STR_CMD_ARG_HELP]}")
								MsgAdd $GC_MSGT_SUCCESS "Got to Bottle Configuration Help" G_GLBL_VAR_ARY
							;;
						esac
					fi
				;;

# -----------------
# Wine Manager Mode
# -----------------
				"${GC_STR_ARY[$E_STR_CMD_ARG_MANAGER]}")
																# Process by option
					case "${G_TOK_VAR_ARY[$E_TOK_OPT]}" in 

# Wine Manager Configuration Read
# -------------------------------
						"${GC_STR_ARY[$E_STR_CMD_ARG_RD]}")
							ConfVarList "${G_TOK_VAR_ARY[$E_TOK_NAME]}" GC_CVAR_WMP_ARY GC_CVAR_WMW_ARY G_GLBL_VAR_ARY GC_STR_ARY
						;;

# Wine Manager Configuration Write
# --------------------------------
						"${GC_STR_ARY[$E_STR_CMD_ARG_WR]}")
							if VarValChk "${G_TOK_VAR_ARY[$E_TOK_NAME]}" "${G_TOK_VAR_ARY[$E_TOK_VAL]}" GC_CVAR_WMP_ARY GC_CVAR_WMW_ARY G_TMP_INT G_GLBL_VAR_ARY; then
																# If protected variable
								if [ $G_TMP_INT -eq $GC_FUNCS_VarTypeChk_P ]; then
									ErrAdd $WM_ERR_CVAR_WR "\"${G_TOK_VAR_ARY[$E_TOK_NAME]}\" is a Protected Wine Manager Variable, it cannot be written" G_GLBL_VAR_ARY
								else
																# Write new variable value
									KeyAddWr "${G_TOK_VAR_ARY[$E_TOK_NAME]}" "${G_TOK_VAR_ARY[$E_TOK_VAL]}" "${GC_STR_ARY[$E_STR_WM_CONF_FILE]}"
									l_RetStat=$?
									if [ $l_RetStat -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
										ErrAdd $(($WM_ERR_TOTAL+$l_RetStat)) "COMMAND conf${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${G_TOK_VAR_ARY[$E_TOK_NAME]}\", Value = \"${G_TOK_VAR_ARY[$E_TOK_VAL]}\", File = \"${GC_STR_ARY[$E_STR_WM_CONF_FILE]}\"" G_GLBL_VAR_ARY
										break
									fi
									ConfVarList "${G_TOK_VAR_ARY[$E_TOK_NAME]}" GC_CVAR_WMP_ARY GC_CVAR_WMW_ARY G_GLBL_VAR_ARY GC_STR_ARY
								fi
							fi
						;;

# Wine Manager Configuration Delete
# ---------------------------------
						"${GC_STR_ARY[$E_STR_CMD_ARG_DEL]}")
																# Get variable type
							VarTypeChk "${G_TOK_VAR_ARY[$E_TOK_NAME]}" GC_CVAR_WMP_ARY GC_CVAR_WMW_ARY G_GLBL_VAR_ARY
																# If protected variable
							if [ $? -eq $GC_FUNCS_VarTypeChk_P ]; then
								ErrAdd $WM_ERR_CVAR_DEL "\"${G_TOK_VAR_ARY[$E_TOK_NAME]}\" is a Protected Wine Manager Variable" G_GLBL_VAR_ARY
							else
																# Delete variable value
								KeyDel "${G_TOK_VAR_ARY[$E_TOK_NAME]}" "${GC_STR_ARY[$E_STR_WM_CONF_FILE]}"
								l_RetStat=$?
																# If it exists
								if [ $l_RetStat -eq $GC_KF_ERR_NONE ];then
									MsgAdd $GC_MSGT_INFO "Configuration variable \"${G_TOK_VAR_ARY[$E_TOK_NAME]}\" deleted from Wine Manager" G_GLBL_VAR_ARY
								else					# If it doesn't exist
									MsgAdd $GC_MSGT_INFO "Configuration variable \"${G_TOK_VAR_ARY[$E_TOK_NAME]}\" doesn't exist in Wine Manager" G_GLBL_VAR_ARY
								fi
							fi
						;;

# Wine Manager Configuration Help
# -------------------------------
						"${GC_STR_ARY[$E_STR_CMD_ARG_HELP]}")
							MsgAdd $GC_MSGT_SUCCESS "Got to Wine Manager Configuration Help" G_GLBL_VAR_ARY
						;;
					esac
				;;
			esac
		fi
	fi
	DbgPrint "COMMAND conf: Exiting."
	;;

#
# ---------------
# Console Command
# ---------------
#
"${GC_STR_ARY[$E_STR_CMD_CONSOLE]}")
	DbgPrint "CMD console: Entered."
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# Check arguments, bottle existence, and not system
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY && IsNotSys "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
																# Get bottle pathname
		G_TMP_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"
																# Create full bottle pathname
		G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
																# Bottle conf file
		G_TMP_BTL_CONF_FILE="$G_TMP_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}"
																# Get env file 
		KeyRd "${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}" "G_TMP_BTL_ENV_FILE" "$G_TMP_BTL_CONF_FILE"
		G_TMP_STAT=$?
		if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
																# If fail return Standard Script error code
			ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "install${GC_SEP_FTRC}KeyRd${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_ENVSCR]}\", File = \"$G_TMP_BTL_CONF_FILE\"" G_GLBL_VAR_ARY
		else													# If succeed, launch console in shell
																# Output colored subshell start msg
			G_TMP_STR="\e[1;33mInvoking $ThisNameUser console subshell for bottle \"$G_TMP_BTL_NAME\". After installation type 'exit'.\e[0m"
			echo -e "$G_TMP_STR"
																# Launch from subshell
			( BottleLaunchShell "$G_TMP_BTL_NAME" "$G_TMP_BTL_ENV_FILE" GC_STR_ARY )
																# Output red subshell exit msg
			G_TMP_STR="\e[1;31mExited $ThisNameUser console subshell.\e[0m"
			echo -e "$G_TMP_STR"
		fi
	fi
	
	DbgPrint "CMD console: Exiting."
	;;

#
# ---------------------
# Create Bottle Command
# ---------------------
#
"${GC_STR_ARY[$E_STR_CMD_CREATE]}")
	DbgPrint "COMMAND Create: Entered."
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "${GC_STR_ARY[$E_STR_TOKSTR_WINE_VER]} ${GC_STR_ARY[$E_STR_TOKSTR_ENV]} ${GC_STR_ARY[$E_STR_TOKSTR_SUBMENU]}" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY; then
																# If no env file input
		if [ ${G_TOK_VAR_ARY[$E_TOK_ENVF]} -eq 0 ]; then
			G_TOK_VAR_ARY[$E_TOK_ENV]="default"		# Set to default
		fi
																# Try to create bottle
		BottleCreate "${G_TOK_VAR_ARY[$E_TOK_BTL]}" "${G_TOK_VAR_ARY[$E_TOK_WINE_VER]}" "${G_TOK_VAR_ARY[$E_TOK_ENV]}" "${G_TOK_VAR_ARY[$E_TOK_SUBMENU]}" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_DSKTP_SUBPATH_ARY
		G_TMP_STAT=$?
		if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# If successful try to mount bottle
			BottleMount "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
		fi
	fi
																# If no error
	if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
		DbgPrint "COMMAND Create: Wine bottle \"${G_TOK_VAR_ARY[$E_TOK_BTL]}\" successfully created."
		MsgAdd $GC_MSGT_SUCCESS "Wine bottle \"${G_TOK_VAR_ARY[$E_TOK_BTL]}\" successfully created" G_GLBL_VAR_ARY
	else														# If error try to delete bottle
		DbgPrint "COMMAND Create: Wine bottle \"${G_TOK_VAR_ARY[$E_TOK_BTL]}\" create failed."
		rm -r "{GC_STR_ARY[$E_STR_WM_BTL_DIR]/${G_TOK_VAR_ARY[$E_TOK_BTL]}"	>/dev/null 2>&1
	fi
	
	DbgPrint "COMMAND Create: Exiting."
	;;

#
# ---------------
# Default Command
# ---------------
#
# When a bottle is set as default ~/.winemgr/wine_dflt is linked to whatever wine version it uses, and the ~/.wine directory is linked to the bottle/wine. So
# when you issue "which wine" it will say /home/phalynx/.winemgr/wine_dflt/bin/wine, and all the wine variables in .profile will point to it.
#
# When there's no default bottle the ~/.winemgr/wine_dflt and ~/.wine links are simply deleted. Now everything will points to whatever wine version and ~/.wine is primary on the host.
#
# Note that if ~/.wine is an actual directory and not a link then it won't be changed, and is an error.
#
"${GC_STR_ARY[$E_STR_CMD_DEFAULT]}")
	DbgPrint "COMMAND default: Processing"
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay and not system bottle
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && IsNotSys "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
																# Get default bottle name
		G_TMP_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"
													
		if [ ! -z "$G_TMP_BTL_NAME" ]; then			# If we have a bottle
			DbgPrint "COMMAND default: Verifying bottle \"$G_TMP_BTL_NAME\" exists."
																# Check if bottle exists
			BottleExists "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY
			G_TMP_STAT=$?
		fi

		if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then	# If no error
																# Write new default wine bottle to wine manager conf
			DbgPrint "COMMAND default: Writing default bottle to conf file, Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_DFLT]}\", Value = \"$G_TMP_BTL_NAME\", File = \"${GC_STR_ARY[$E_STR_WM_CONF_FILE]}\"."
			KeyWr "${GC_STR_ARY[$E_STR_KEY_BTL_DFLT]}" "$G_TMP_BTL_NAME" "${GC_STR_ARY[$E_STR_WM_CONF_FILE]}"
			G_TMP_STAT=$?
			if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
				DbgPrint "COMMAND default: Write key failed with status = \"$G_TMP_STAT\"."
																# If fail create Standard Script error code
				ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "default${GC_SEP_FTRC}KeyWr${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_DFLT]}\", File = \"${GC_STR_ARY[$E_STR_WM_CONF_FILE]}\"" G_GLBL_VAR_ARY
			else											# If key written
																# Enable default bottle
				BottleDefaultEnb G_GLBL_VAR_ARY GC_STR_ARY G_TMP_BTL_NAME G_TMP_DIR_NAME 
				G_TMP_STAT=$?
																# If no error
				if [ $G_TMP_STAT -eq $WM_ERR_NONE ]; then
																# Create default bottle message
					if [ ! -z "$G_TMP_BTL_NAME" ]; then
						MsgAdd $GC_MSGT_SUCCESS "Wine bottle \"$G_TMP_BTL_NAME\" set as default" G_GLBL_VAR_ARY
					else
						MsgAdd $GC_MSGT_SUCCESS "No default Wine bottle, The system .wine bottle (if any) will be the default" G_GLBL_VAR_ARY
					fi
																# Create default Wine dir msg
					if [ ! -z "$G_TMP_DIR_NAME" ]; then
						MsgAdd $GC_MSGT_SUCCESS "Wine version \"$G_TMP_DIR_NAME\" set as default" G_GLBL_VAR_ARY
					else
						MsgAdd $GC_MSGT_SUCCESS "No default Wine version, The system wine version (if any) is the default" G_GLBL_VAR_ARY
					fi
				fi
			fi
		fi
	fi

	DbgPrint "COMMAND default: Exiting"
	;;

#
# --------------------
# Deinitialize Command
# --------------------
#
"${GC_STR_ARY[$E_STR_CMD_DEINIT]}")
	DbgPrint "COMMAND deinit: Entered"
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if ArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV" G_GLBL_VAR_ARY; then
																# Deinitialize
		DbgPrint "COMMAND deinit: Deinitializing Wine Manager system"
		WineManagerDeinit G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY
		G_TMP_STAT=$?
		if [ $G_TMP_STAT -eq $WM_ERR_NONE ]; then
			MsgAdd $GC_MSGT_SUCCESS "Wine manager deinitialization successful" G_GLBL_VAR_ARY
		else
			MsgAdd $GC_MSGT_ERR "Wine manager deinitialization failed" G_GLBL_VAR_ARY
		fi
	fi

	DbgPrint "COMMAND deinit: Exiting"
	;;

#
# ---------------------
# Delete Bottle Command
# ---------------------
#
"${GC_STR_ARY[$E_STR_CMD_DELETE]}")
	DbgPrint "COMMAND delete: Processing delete bottle or backup command."
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} ${GC_STR_ARY[$E_STR_TOKSTR_OPT]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay and not system bottle
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && IsNotSys "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
																# Get bottle name
		G_TMP_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"

		case "${G_TOK_VAR_ARY[$E_TOK_OPT]}" in 
																# If delete bottle
			"${GC_STR_ARY[$E_STR_CMD_ARG_BOTTLE]}")
																# If bottle exists
				BottleExists "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY
				G_TMP_STAT=$?
				if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# Verify bottle delete request
					AskYesNo "Are you sure you want to delete bottle \"$G_TMP_BTL_NAME\"" G_TMP_STR

					case "$G_TMP_STR" in 
						y)										# Yes
							echo "Deleting Wine bottle \"$G_TMP_BTL_NAME\" ..."
																# If no error load success message
							BottleDelete "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
							G_TMP_STAT=$?
							if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
								MsgAdd $GC_MSGT_SUCCESS "Wine bottle \"$G_TMP_BTL_NAME\" deleted" G_GLBL_VAR_ARY
							fi
						;;

						n)										# No
							MsgAdd $GC_MSGT_SUCCESS "Wine bottle \"$G_TMP_BTL_NAME\" delete cancelled" G_GLBL_VAR_ARY
						;;

						*)										# Load error info if invalid response from AskYesNo
							ErrAdd $WM_ERR_INV_RESP "Response: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
						;;
					esac
				fi
			;;
																# If delete backup bottle
			"${GC_STR_ARY[$E_STR_CMD_ARG_BACKUP]}")
																# If bottle exists
				BackupBottleExists "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY
				G_TMP_STAT=$?
				if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# Verify bottle delete request
					AskYesNo "Are you sure you want to delete backup bottle \"$G_TMP_BTL_NAME\"" G_TMP_STR

					case "$G_TMP_STR" in 
						y)										# Yes
																# Backup bottle pathname
							G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_BCKP_DIR]}/$G_TMP_BTL_NAME"
							echo "Deleting back up Wine bottle \"$G_TMP_BTL_PATHNAME\" ..."
																# Delete backup
							rm -rf "$G_TMP_BTL_PATHNAME" >/dev/null 2>&1
							G_TMP_STAT=$?
							if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
																# Load error info if fail
								ErrAdd $WM_ERR_DIR_DEL "Backup bottle delete failed with exit status: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
							else
								MsgAdd $GC_MSGT_SUCCESS "Back up Wine bottle \"$G_TMP_BTL_NAME\" deleted" G_GLBL_VAR_ARY
							fi
						;;

						n)										# No
							MsgAdd $GC_MSGT_SUCCESS "Back up Wine bottle \"$G_TMP_BTL_NAME\" delete cancelled" G_GLBL_VAR_ARY
						;;

						*)										# Load error info if invalid response from AskYesNo
							ErrAdd $WM_ERR_INV_RESP "Response: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
						;;
					esac
				fi
			;;

			*)													# Unrecognized argument
				ErrAdd $WM_ERR_UNK_ARG "Argument: Option \"${G_TOK_VAR_ARY[$E_TOK_OPT]}\"" G_GLBL_VAR_ARY
			;;
		esac
	fi
	DbgPrint "COMMAND delete: Exiting."
	;;

#
# ---------------------
# Edit Bottle Command
# ---------------------
#
"${GC_STR_ARY[$E_STR_CMD_EDIT]}")
	DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_EDIT]}: Processing."
																# Parse arguments
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} ${GC_STR_ARY[$E_STR_TOKSTR_OLD_VAL]} ${GC_STR_ARY[$E_STR_TOKSTR_VAL]}" "${GC_STR_ARY[$E_STR_TOKSTR_SUB_DIR]}" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# Check arguments, bottle existence, not XDG or default
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY && IsNotXdgDefaultSys "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
		G_TMP_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"
		G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
		DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_EDIT]}: Bottle = \"$G_TMP_BTL_NAME\", Pathname = \"$G_TMP_BTL_PATHNAME\"."
																# Create dir head path
		G_TMP_DIR_NAME="$G_TMP_BTL_PATHNAME/${GC_XDG_DIR_ARY[$E_XDG_PRI_BOTTLE]}"
		G_TMP_ARY=()										# Clear dir array
		G_TMP_FLAG=0										# Clear dir processed flag
																# If subdirectory specified
		if [ ${G_TOK_VAR_ARY[$E_TOK_SUB_DIRF]} -eq 1 ]; then
																# Create single dir array
			G_TMP_ARY=( "$G_TMP_DIR_NAME/${G_TOK_VAR_ARY[$E_TOK_SUB_DIR]}" )
			DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_EDIT]}: Added \"$G_TMP_DIR_NAME/${G_TOK_VAR_ARY[$E_TOK_SUB_DIR]}\" to single directory array."
		else													# Else get directory subpath for desktop files
			for G_TMP_SUBDIR in "${GC_XDG_DSKTP_SUBPATH_ARY[@]}"
			do													# Add dir to array
				G_TMP_ARY+=( "$G_TMP_DIR_NAME/$G_TMP_SUBDIR" )
				DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_EDIT]}: Added \"$G_TMP_DIR_NAME/$G_TMP_SUBDIR\" to multiple directory array."
			done
		fi
																# Process all directories
		for G_TMP_DIR_NAME in "${G_TMP_ARY[@]}"
		do
			if [ -e "$G_TMP_DIR_NAME" ]; then		# If dir exists
				G_TMP_FLAG=1								# Set dir processed flag
				cd "$G_TMP_DIR_NAME"						# Change to it
																# Process all .desktop files
				find . -print | grep -i '.desktop' | while read G_TMP_FILE_NAME
				do
					DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_EDIT]}: Changing \"$${G_TOK_VAR_ARY[$E_TOK_OLD_VAL]}\" to \"${G_TOK_VAR_ARY[$E_TOK_VAL]}\" in desktop file '$G_TMP_FILE_NAME'."
					sed -i "s#${G_TOK_VAR_ARY[$E_TOK_OLD_VAL]}#${G_TOK_VAR_ARY[$E_TOK_VAL]}#g" "$G_TMP_FILE_NAME"
				done
			else												# If dir doesn't exist
				DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_EDIT]}: Directory \"$G_TMP_DIR_NAME\" doesn't exist, skipping."
				MsgAdd $GC_MSGT_WARN "Directory \"$G_TMP_DIR_NAME\" doesn't exist, skipping" G_GLBL_VAR_ARY
			fi
		done

		if [ $G_TMP_FLAG -eq 1 ]; then
			MsgAdd $GC_MSGT_SUCCESS "Wine bottle \"$G_TMP_BTL_NAME\" Exec edit successfully completed" G_GLBL_VAR_ARY
		else
			MsgAdd $GC_MSGT_WARN "No directories processed for Wine bottle \"$G_TMP_BTL_NAME\"" G_GLBL_VAR_ARY
		fi
	fi

	DbgPrint "COMMAND ${GC_STR_ARY[$E_STR_CMD_EDIT]}: Exiting"
	;;

#
# ------------------
# Initialize Command
# ------------------
#
"${GC_STR_ARY[$E_STR_CMD_INIT]}")
	DbgPrint "COMMAND init: Entered"

	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if ArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV" G_GLBL_VAR_ARY; then
		DbgPrint "COMMAND init: Initializing Wine Manager system"
		WineManagerInit G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
		G_TMP_STAT=$?
		if [ $G_TMP_STAT -eq $WM_ERR_NONE ]; then
			MsgAdd $GC_MSGT_SUCCESS "Wine manager initialization successful" G_GLBL_VAR_ARY
		else
			MsgAdd $GC_MSGT_ERR "Wine manager initialization failed" G_GLBL_VAR_ARY
		fi
	fi

	DbgPrint "COMMAND init: Exiting"
	;;

#
# ------------
# List Command
# ------------
#
"${GC_STR_ARY[$E_STR_CMD_LIST]}")
	DbgPrint "COMMAND list: Processing command"
																# Verify correct options
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" "${GC_STR_ARY[$E_STR_TOKSTR_OPT]}" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if ArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY; then
		case "${G_TOK_VAR_ARY[$E_TOK_OPT]}" in 
																# List bottles
			"${GC_STR_ARY[$E_STR_CMD_ARG_BOTTLE]}")
				BottleList 0 G_GLBL_VAR_ARY GC_STR_ARY
			;;
																# List backup bottles
			"${GC_STR_ARY[$E_STR_CMD_ARG_BACKUP]}")
				BottleList 1 G_GLBL_VAR_ARY GC_STR_ARY
			;;

			"")												# Default is list bottles
				BottleList 0 G_GLBL_VAR_ARY GC_STR_ARY
			;;

			*)													# Unrecognized argument
				ErrAdd $WM_ERR_UNK_ARG "Argument: \"${G_TOK_VAR_ARY[$E_TOK_OPT]}\"" G_GLBL_VAR_ARY
			;;
		esac
	fi

	DbgPrint "COMMAND list: Exiting."
	;;

#
# ---------------
# Migrate Command
# ---------------
#
"${GC_STR_ARY[$E_STR_CMD_MIGRATE]}")
	DbgPrint "COMMAND migrate: Processing command"

	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_OPT]}" "${GC_STR_ARY[$E_STR_TOKSTR_VAL]}" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if IsDeinitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY; then
		G_TMP_OPT="${G_TOK_VAR_ARY[$E_TOK_OPT]}"
		DbgPrint "COMMAND migrate: Option = \"$G_TMP_OPT\"."

		case "$G_TMP_OPT" in 
			copy|move)										# Copy/move
																# If no destination directory
				if [ ${G_TOK_VAR_ARY[$E_TOK_VALF]} -ne 1 ]; then
					ErrAdd $WM_ERR_PARM_MISS "Mandatory destination directory not specified" G_GLBL_VAR_ARY
				else
																# Get absolute source dir without symlink
					DbgPrint "COMMAND migrate: Raw current root directory source = \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\"."
					G_TMP_DIR_NAME=`realpath -L -m "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}"`
					DbgPrint "COMMAND migrate: Absolute root directory source = \"$G_TMP_DIR_NAME\"."
																# Get destination directory
					G_TMP_DIR_DEST="${G_TOK_VAR_ARY[$E_TOK_VAL]}"				
																# If dir already exists.
					if [ -e "$G_TMP_DIR_DEST" ]; then
						ErrAdd $WM_ERR_DIR_EXISTS "Destination directory already exists - \"$G_TMP_DIR_DEST\"" G_GLBL_VAR_ARY
					else										# Else make sure we can read/write
						G_TMP_STR=`dirname "$G_TMP_DIR_DEST"`
						if [[ ! -w "$G_TMP_STR" || ! -r "$G_TMP_STR" ]]; then
							ErrAdd $WM_ERR_DIR_RW "Directory not read/write \"$G_TMP_STR\"" G_GLBL_VAR_ARY
						fi
					fi
				fi
			;;

			todir)											# Convert to directory
																# If destination directory
				if [ ${G_TOK_VAR_ARY[$E_TOK_VALF]} -ne 0 ]; then
					ErrAdd $WM_ERR_PARM_INV "Destination directory is not used with todir" G_GLBL_VAR_ARY
																# If source is not a link
				elif [ ! -L "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}" ]; then
					ErrAdd $WM_ERR_LNK_NEXIST "Can't convert, \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\" is not a link" G_GLBL_VAR_ARY
				else
																# Source is link
					G_TMP_DIR_NAME="${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}"
																# Destination is link target
					DbgPrint "COMMAND migrate: Raw current root directory destination = \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\"."
					G_TMP_DIR_DEST=`realpath -L -m "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}"`
					DbgPrint "COMMAND migrate: Absolute root directory destination = \"$G_TMP_DIR_NAME\"."
				fi
			;;

			tolnk)											# Convert to link
																# If no destination directory
				if [ ${G_TOK_VAR_ARY[$E_TOK_VALF]} -ne 1 ]; then
					ErrAdd $WM_ERR_PARM_MISS "Mandatory link name not specified" G_GLBL_VAR_ARY
				else
																# Get absolute source dir without symlink
					DbgPrint "COMMAND migrate: Raw current root directory source = \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\"."
					G_TMP_DIR_NAME=`realpath -L -m "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}"`
					DbgPrint "COMMAND migrate: Absolute root directory source = \"$G_TMP_DIR_NAME\"."
																# Get target link
					G_TMP_DIR_DEST="${G_TOK_VAR_ARY[$E_TOK_VAL]}"				
																# If link/dir already exists.
					if [ -e "$G_TMP_DIR_DEST" ]; then
						ErrAdd $WM_ERR_DIR_EXISTS "Link name already exists - \"$G_TMP_DIR_DEST\"" G_GLBL_VAR_ARY
					else										# Else make sure we can read/write
						G_TMP_STR=`dirname "$G_TMP_DIR_DEST"`
						if [[ ! -w "$G_TMP_STR" || ! -r "$G_TMP_STR" ]]; then
							ErrAdd $WM_ERR_DIR_RW "Link point not read/write \"$G_TMP_STR\"" G_GLBL_VAR_ARY
						fi
					fi
				fi
			;;

			*)													# Unrecognized option
				ErrAdd $WM_ERR_UNK_ARG "Argument: \"${G_TOK_VAR_ARY[$E_TOK_OPT]}\"" G_GLBL_VAR_ARY
			;;
		esac
	fi

	if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then

# Warn before copy/move/convert
# -----------------------------
																# Get source dir without trailing slash
		G_TMP_DIR_NAME=$(echo "$G_TMP_DIR_NAME" | sed 's#/$##')
																# Get dest dir without trailing slash
		G_TMP_DIR_DEST=$(echo "$G_TMP_DIR_DEST" | sed 's#/$##')

																# If converting link
		case "$G_TMP_OPT" in
			copy|move)
				G_TMP_STR="Are you sure you want to $G_TMP_OPT the Wine Manager root directory at \"$G_TMP_DIR_NAME\" to \"$G_TMP_DIR_DEST\""
			;;

			todir)
				G_TMP_STR="Are you sure you want to convert the linked Wine Manager root directory at \"$G_TMP_DIR_NAME\" to its absolute directory \"$G_TMP_DIR_DEST\""
			;;

			tolnk)
				G_TMP_STR="Are you sure you want to convert the absolute Wine Manager root directory at \"$G_TMP_DIR_NAME\" to linked directory \"$G_TMP_DIR_DEST\""
			;;
		esac

		AskYesNo "$G_TMP_STR" G_TMP_STR
		case "$G_TMP_STR" in 
			y)													# Yes
				G_TMP_FLAG=0								# Clear cancel flag
			;;

			n)													# No
				MsgAdd $GC_MSGT_SUCCESS "Wine Manager data directory migration cancelled" G_GLBL_VAR_ARY
				G_TMP_FLAG=1								# Set cancel flag
			;;

			*)													# Load error info if invalid response from AskYesNo
				ErrAdd $WM_ERR_INV_RESP "Response: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
				G_TMP_FLAG=1								# Set cancel flag
			;;
		esac

# Source/Destination Preprocessing
# --------------------------------
																# If no error or cancel
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && $G_TMP_FLAG -ne 1 ]]; then

			case "$G_TMP_OPT" in 
				copy)											# Copy processing

					echo -e "Copying Wine Manager data directory \"$G_TMP_DIR_NAME\" to \"$G_TMP_DIR_DEST\", this could take awhile ..."
					DbgPrint "COMMAND migrate: Executing \"rsync -aAXvl \"$G_TMP_DIR_NAME/\" \"$G_TMP_DIR_DEST\"\"."
					rsync -aAXvl "${G_TMP_DIR_NAME}/" "$G_TMP_DIR_DEST"
					G_TMP_STAT=$?
					if [ $G_TMP_STAT -ne 0 ]; then
						ErrAdd $WM_ERR_DIR_COPY "Copy failed with exit status: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
						MsgAdd $GC_MSGT_ERR "Error copying directory, cancelling migration" G_GLBL_VAR_ARY
					else
						echo -e "Wine Manager data directory copy complete."
					fi
				;;

				move)											# Move processing
					echo -e "Moving Wine Manager data directory \"$G_TMP_DIR_NAME\" to \"$G_TMP_DIR_DEST\"."
					mv "$G_TMP_DIR_NAME" "$G_TMP_DIR_DEST"
					G_TMP_STAT=$?
					if [ $G_TMP_STAT -ne 0 ]; then
						ErrAdd $WM_ERR_DIR_MOVE "Move failed with exit status: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
						MsgAdd $GC_MSGT_ERR "Error moving directory, cancelling migration" G_GLBL_VAR_ARY
					else
						echo -e "Wine Manager data directory move complete."
					fi
				;;

				tolnk)										# Convert to link processing
					ln -s "$G_TMP_DIR_NAME" "$G_TMP_DIR_DEST" >/dev/null 2>&1
					G_TMP_STAT=$?
					if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
																# If fail set error code and message
						ErrAdd $WM_ERR_LNK_CREATE "migrate${GC_SEP_FTRC}Fail status: \"$G_TMP_STAT\", Link name: \"$G_TMP_DIR_NAME\", Link target: \"$G_TMP_DIR_DEST\"" G_GLBL_VAR_ARY
					fi
				;;
			esac
																# If no error
			if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
#
# Link Change Processing
# ----------------------
# If source is linked and not coonverting don't change bottle entries to absolute directories, just change directory link.

																# If source is a link and not converting to directory or link
				if [[ -L "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}" && "$G_TMP_OPT" != "todir"  && "$G_TMP_OPT" != "tolnk" ]]; then
					echo -e "Root data directory is a link, link will be changed to new root directory \"$G_TMP_DIR_DEST\""
																# Delete old link
					rm "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}" >/dev/null 2>&1
					G_TMP_STAT=$?
					if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
																# If fail set error code and message
						ErrAdd $WM_ERR_LNK_DEL "migrate${GC_SEP_FTRC}Fail status: \"$G_TMP_STAT\", Link name: \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\"" G_GLBL_VAR_ARY
					else
																# Create new link
						ln -s "$G_TMP_DIR_DEST" "${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}" >/dev/null 2>&1
						G_TMP_STAT=$?
						if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
																# If fail set error code and message
							ErrAdd $WM_ERR_LNK_CREATE "migrate${GC_SEP_FTRC}Fail status: \"$G_TMP_STAT\", Link name: \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\", Link target: \"$G_TMP_DIR_DEST\"" G_GLBL_VAR_ARY
						fi
					fi
																# If no error
					if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then

						MsgAdd $GC_MSGT_SUCCESS "Root directory \"$G_TMP_DIR_NAME\" $G_TMP_OPT to \"$G_TMP_DIR_DEST\" successful. Link \"${G_GLBL_VAR_ARY[$E_GLBL_ROOT]}\" set to new directory \"$G_TMP_DIR_DEST\"" G_GLBL_VAR_ARY
						MsgAdd $GC_MSGT_SUCCESS "Migration complete" G_GLBL_VAR_ARY
					fi
#
# Bottle Change Processing
# ------------------------
# Bottles
# ~~~~~~~
				else
					echo -e "Processing all bottles for new location ..."
																# Get new dir pathname for bottles
					G_TMP_BTL_DIR="$G_TMP_DIR_DEST/btl"
																# If directory not empty

					if [ "$(ls -A "$G_TMP_BTL_DIR")" ]; then
#					if [ `ls -A "$G_TMP_BTL_DIR"` ]; then
																# Get all bottles
						G_TMP_ARY=(`ls -1 "$G_TMP_BTL_DIR"`)
						DbgPrint "COMMAND migrate: Number of bottles = ${#G_TMP_ARY[@]}"

						for G_TMP_BTL_NAME in "${G_TMP_ARY[@]}"
						do
							G_TMP_BTL_PATHNAME="$G_TMP_BTL_DIR/$G_TMP_BTL_NAME"
							DbgPrint "COMMAND migrate: Processing bottle pathname = $G_TMP_BTL_PATHNAME"

							BottleParamChange "$G_TMP_BTL_PATHNAME" "$G_TMP_DIR_NAME" "$G_TMP_DIR_DEST" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_DSKTP_SUBPATH_ARY
							G_TMP_STAT=$?
																# If read fail return Standard Script error code
							if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
								MsgPrepend "migrate${GC_SEP_FTRC}" G_GLBL_VAR_ARY
								break
							fi
						done
					fi
#
# Backup Bottles
# ~~~~~~~~~~~~~~
																# If no error
					if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
						echo -e "Processing all backup bottles for new location ..."
																# Get new dir pathname for backup bottles
						G_TMP_BTL_DIR="$G_TMP_DIR_DEST/backup"
																# If directory not empty
						if [ "$(ls -A "$G_TMP_BTL_DIR")" ]; then
#						if [ `ls -A "$G_TMP_BTL_DIR"` ]; then
																# Get all backup bottles
							G_TMP_ARY=(`ls -1 "$G_TMP_BTL_DIR"`)
							DbgPrint "COMMAND migrate: Number of bottles = ${#G_TMP_ARY[@]}"

							for G_TMP_BTL_NAME in "${G_TMP_ARY[@]}"
							do
								G_TMP_BTL_PATHNAME="$G_TMP_BTL_DIR/$G_TMP_BTL_NAME"
								DbgPrint "COMMAND migrate: Processing backup bottle pathname = $G_TMP_BTL_PATHNAME"

								BottleParamChange "$G_TMP_BTL_PATHNAME" "$G_TMP_DIR_NAME" "$G_TMP_DIR_DEST" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_DSKTP_SUBPATH_ARY
								G_TMP_STAT=$?
																# If read fail return Standard Script error code
								if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
																# Prepend function name to error message
									MsgPrepend "migrate${GC_SEP_FTRC}" G_GLBL_VAR_ARY
									break
								fi
							done
						fi
					fi
																# If no error
					if [ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE ]; then
						MsgAdd $GC_MSGT_SUCCESS "Migration complete. Make sure to change \"WINEMGR_ROOT\" environment variable before using new location" G_GLBL_VAR_ARY
					fi
				fi
			fi
		fi
	fi

	DbgPrint "COMMAND migrate: Exiting."
	;;

#
# ---------------
# Refresh Command
# ---------------
#
"${GC_STR_ARY[$E_STR_CMD_REFRESH]}")
	DbgPrint "COMMAND refresh: Entered"
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY; then
																# If single bottle
		if [ ! -z "${G_TOK_VAR_ARY[$E_TOK_BTL]}" ]; then
			DbgPrint "COMMAND refresh: Creating one bottle array."
																# If bottle exists
			BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY;
			G_TMP_STAT=$?
			if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# Create one bottle array
				G_TMP_ARY=( "${G_TOK_VAR_ARY[$E_TOK_BTL]}" )
			else
				G_TMP_ARY=( )								# If it doesn't clear array
			fi
		else													# If all bottles
			DbgPrint "COMMAND refresh: Creating all bottles array."
																# Create all bottle array
			G_TMP_ARY=( `ls -1 "${GC_STR_ARY[$E_STR_WM_BTL_DIR]}"` )
																# If no bottles
			if [ ${#G_TMP_ARY[@]} -eq 0 ]; then
																# Set success message
				MsgAdd $GC_MSGT_SUCCESS "There are no bottles, can't refresh anything" G_GLBL_VAR_ARY
			fi
		fi

		if [ ${#G_TMP_ARY[@]} -gt 0 ]; then			# If bottles to process
																# Always refresh Wine Manager bottle
			G_TMP_ARY+=( "${GC_STR_ARY[$E_STR_WM_SYS_BTL_NAME]}" )
			for G_TMP_BTL_NAME in "${G_TMP_ARY[@]}";
			do
																# Create full bottle pathname
				G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
				DbgPrint "COMMAND refresh: Rebuilding Bottle Translate Menu for \"$G_TMP_BTL_PATHNAME\"."
																# Build bottle translate menu
				BuildTranslateXDG "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
				G_TMP_STAT=$?
				if [ $G_TMP_STAT -ne $WM_ERR_NONE ];then
					break										# Exit if fail
				fi
				MsgAdd $GC_MSGT_SUCCESS "Wine bottle \"$G_TMP_BTL_NAME\" Host XDG refreshed" G_GLBL_VAR_ARY
			done
		fi
	fi
																# If no error and we processed bottles
	if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && ${#G_TMP_ARY[@]} -gt 0 ]]; then
		DbgPrint "COMMAND refresh: Executing user Custom Menu Refresh command"
																# Refresh host menu
		CustomXdgRefresh "${G_GLBL_VAR_ARY[$E_GLBL_XDG_REFRESH]}" G_GLBL_VAR_ARY
	fi
	DbgPrint "COMMAND refresh: Exiting"
	;;

#
# ---------------
# Restore Command
# ---------------
#
"${GC_STR_ARY[$E_STR_CMD_RESTORE]}")
	DbgPrint "COMMAND restore: Processing"
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay, backup bottle exists
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY && BackupBottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY; then
		G_TMP_FLAG=0										# Clear cancel flag
																# Get backup bottle name/pathname
		G_TMP_WRK_BTL_NAME="${G_TOK_VAR_ARY[$E_TOK_BTL]}"
		G_TMP_WRK_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_BCKP_DIR]}/$G_TMP_WRK_BTL_NAME"
		DbgPrint "COMMAND restore: Bakcup bottle name = \"$G_TMP_WRK_BTL_NAME\", Pathname = \"$G_TMP_WRK_BTL_PATHNAME\"."
																# Create bottle name/pathname
		G_TMP_BTL_NAME="$G_TMP_WRK_BTL_NAME"
		G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
		G_TMP_CONF_PATHNAME="$G_TMP_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}"
																# If  bottle exists
		if [ -e "$G_TMP_BTL_PATHNAME" ]; then
			read -p "Are you sure you want to overwrite bottle \"$G_TMP_BTL_PATHNAME\" (y/n)? " G_TMP_STR
			case "$G_TMP_STR" in 
				y|Y)											# Yes
					DbgPrint "Deleting bottle \"$G_TMP_BTL_PATHNAME\""
																# Delete bottle
					echo "Deleting bottle \"$G_TMP_BTL_PATHNAME\" ..."
					BottleDelete "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
					G_TMP_STAT=$?
					if [ $G_TMP_STAT -eq $WM_ERR_NONE ]; then
						echo "Bottle \"$G_TMP_WRK_BTL_PATHNAME\" deleted."
					fi
				;;

				n|N)											# No
					MsgAdd $GC_MSGT_SUCCESS "Restore bottle \"$G_TMP_WRK_BTL_NAME\" cancelled" G_GLBL_VAR_ARY
					G_TMP_FLAG=1							# Set cancel flag
				;;

				*)												# Load error info if invalid response from AskYesNo
					ErrAdd $WM_ERR_INV_RESP "Response: \"$G_TMP_STR\"" G_GLBL_VAR_ARY
				;;
			esac
		fi
																# If no error or cancel
		if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -eq $WM_ERR_NONE && $G_TMP_FLAG -ne 1 ]]; then
																# Copy backup to bottle
			echo -e "Restoring backup bottle \"$G_TMP_WRK_BTL_PATHNAME\" to \"$G_TMP_BTL_PATHNAME\" ..."
			cp -r "$G_TMP_WRK_BTL_PATHNAME" "$G_TMP_BTL_PATHNAME" >/dev/null 2>&1
			G_TMP_STAT=$?									# If copy failed
			if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
				ErrAdd $WM_ERR_FILE_COPY "Backup bottle \"$G_TMP_WRK_BTL_PATHNAME\" copy to bottle \"$G_TMP_BTL_PATHNAME\" failed with status \"$G_TMP_STAT\"" G_GLBL_VAR_ARY
			else
																# Write XDG disable to bottle config
				KeyWr "${GC_STR_ARY[$E_STR_KEY_BTL_XDG_ENB]}" 0 "$G_TMP_CONF_PATHNAME"
				G_TMP_STAT=$?
				if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
					ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "COMMAND restore: KeyWr${GC_SEP_FTRC}Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_XDG_ENB]}\", Value = \"$GC_BTL_XDG_ENB\", File = \"$G_TMP_CONF_PATHNAME\"" G_GLBL_VAR_ARY
				else
																# Mount bottle
					BottleMount "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
					G_TMP_STAT=$?							# Save status
																# If fail
					if [ $G_TMP_STAT -ne $WM_ERR_NONE ]; then
						MsgAdd $GC_MSGT_ERR "Bottle \"$G_TMP_BTL_NAME\" mount failed" G_GLBL_VAR_ARY
					else
																# Add bottle menu
						if BottleWmMenuAdd "$G_TMP_BTL_NAME" G_GLBL_VAR_ARY GC_STR_ARY; then
																# Refresh Host XDG
							CustomXdgRefresh "${G_GLBL_VAR_ARY[$E_GLBL_XDG_REFRESH]}" G_GLBL_VAR_ARY
							MsgAdd $GC_MSGT_SUCCESS "Backup bottle \"$G_TMP_WRK_BTL_PATHNAME\" restored to \"$G_TMP_BTL_PATHNAME\"" G_GLBL_VAR_ARY
						fi
					fi
				fi
			fi
		fi
	fi
	DbgPrint "COMMAND restore: Exiting"
	;;

#
# ---------------
# Version Command
# ---------------
#
"${GC_STR_ARY[$E_STR_CMD_VERSION]}")
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" "" G_TMP_TOK_INV	# Verify correct args
						# Check results
	ArgsRsltChk "$?" "$G_TMP_TOK_INV" G_GLBL_VAR_ARY
	G_TMP_STAT=$?
	if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then		# If arguments okay
		MsgAdd $GC_MSGT_SUCCESS "$ThisAppName Version $ThisVersion" G_GLBL_VAR_ARY
	fi
	;;

#
# -----------
# XDG Command
# -----------
#
"${GC_STR_ARY[$E_STR_CMD_XDG]}")
	DbgPrint "COMMAND xdg: Entered"
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]} ${GC_STR_ARY[$E_STR_TOKSTR_BTL]} ${GC_STR_ARY[$E_STR_TOKSTR_OPT]}" "" G_TMP_TOK_INV
	G_TMP_STAT=$?
																# If arguments okay
	if IsInitArgsRsltChk "$G_TMP_STAT" "$G_TMP_TOK_INV"  G_GLBL_VAR_ARY GC_STR_ARY; then
																# Convert on/off to lowercase
		G_TMP_STR=`echo "${G_TOK_VAR_ARY[$E_TOK_OPT]}" | tr '[:upper:]' '[:lower:]'`
																# If single bottle
		if [ ! -z "${G_TOK_VAR_ARY[$E_TOK_BTL]}" ]; then
			DbgPrint "COMMAND xdg: Creating one bottle array."
																# If bottle exists
			BottleExists "${G_TOK_VAR_ARY[$E_TOK_BTL]}" G_GLBL_VAR_ARY GC_STR_ARY
			G_TMP_STAT=$?
			if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# Create one bottle array
				G_TMP_ARY=( "${G_TOK_VAR_ARY[$E_TOK_BTL]}" )
			else
				G_TMP_ARY=( )								# If it doesn't clear array
			fi
		else													# If all bottles
			DbgPrint "COMMAND xdg: Creating all bottles array."
																# Create all bottle array
			G_TMP_ARY=( `ls -1 "${GC_STR_ARY[$E_STR_WM_BTL_DIR]}"` )
																# If no bottles
			if [ ${#G_TMP_ARY[@]} -eq 0 ]; then
																# Set success message
				MsgAdd $GC_MSGT_SUCCESS "There are no bottles, can't set Host XDG on/off" G_GLBL_VAR_ARY
			fi
		fi

		if [ ${#G_TMP_ARY[@]} -gt 0 ]; then			# If bottles to process

# Turn XDG On
# -----------
			case "$G_TMP_STR" in 
				"on")

# Get All Current XDG Enabled Bottles (in ARY3)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					G_TMP_ARY3=()							# Clear XDG enabled bottle array
					G_TMP_ARY4=()							# Clear enable add bottle name array
																# Create all bottle array
					G_TMP_ARY2=( `ls -1 "${GC_STR_ARY[$E_STR_WM_BTL_DIR]}"` )
					for G_TMP_BTL_NAME in "${G_TMP_ARY2[@]}";
					do
						G_TMP_BTL_PATHNAME="${GC_STR_ARY[$E_STR_WM_BTL_DIR]}/$G_TMP_BTL_NAME"
						G_TMP_CONF_PATHNAME="$G_TMP_BTL_PATHNAME/${GC_STR_ARY[$E_STR_BTL_CONF_FILE]}"
																# Get XDG enable
						KeyRd "${GC_STR_ARY[$E_STR_KEY_BTL_XDG_ENB]}" "G_TMP_INT" "$G_TMP_CONF_PATHNAME"
						G_TMP_STAT=$?						# Save status
																# If fail
						if [ $G_TMP_STAT -ne $GC_KF_ERR_NONE ];then
																# Return Standard Script error code
							ErrAdd $(($WM_ERR_TOTAL+$G_TMP_STAT)) "COMMAND xdg:KeyRd${GC_SEP_FTRC}Status = \"$G_TMP_STAT\", Key = \"${GC_STR_ARY[$E_STR_KEY_BTL_XDG_ENB]}\", File = \"$G_TMP_CONF_PATHNAME\"" G_GLBL_VAR_ARY
							break
						fi	

						DbgPrint "COMMAND xdg: Enable Check - XDG Value for bottle \"$G_TMP_BTL_NAME\" = \"$G_TMP_INT\"."
																# If XDG enabled
						if [ $G_TMP_INT -eq $GC_BTL_XDG_ENB ]; then
							DbgPrint "COMMAND xdg: Adding \"$G_TMP_BTL_NAME\" to enabled array."
																# Add to enabled array
							G_TMP_ARY3+=( $G_TMP_BTL_NAME )
						fi
					done

# Disable Enabled Bottles and Add Them to Enable Array (in ARY4)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
																# If no error
					if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# If XDG enabled bottles
						if [ ${#G_TMP_ARY3[@]} -gt 0 ]; then
							DbgPrint "COMMAND xdg: Disabling currently active bottles ..."
																# Disable them
							if BottleHostXdgDsb G_TMP_ARY3 G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY; then
																# Refresh host Host XDG
#								CustomXdgRefresh "${G_GLBL_VAR_ARY[$E_GLBL_XDG_REFRESH]}" G_GLBL_VAR_ARY
																# Got through previously enabled bottles array
								for G_TMP_BTL_NAME in "${G_TMP_ARY3[@]}";
								do
																# See if it's in new enable array
									G_TMP_FLAG=1			# Set add flag
									for G_TMP_STR in "${G_TMP_ARY[@]}";
									do
										DbgPrint "COMMAND xdg: Check if previously enabled \"$G_TMP_BTL_NAME\" already in enabled array, Check bottle = \"$G_TMP_STR\"."
																# If bottle name already in able array
										if [ "$G_TMP_STR" == "$G_TMP_BTL_NAME" ]; then
											DbgPrint "COMMAND xdg: \"$G_TMP_BTL_NAME\" already in enabled array, clearing add flag."
											G_TMP_FLAG=0	# Clear add flag
											break
										fi
									done
																# If we need to add to enable array
									if [ $G_TMP_FLAG -eq 1 ]; then
										DbgPrint "COMMAND xdg: Adding \"$G_TMP_BTL_NAME\" to enable add array."

										G_TMP_ARY4+=( "$G_TMP_BTL_NAME" )
									fi
								done
							fi
						fi

# Enable Bottle XDGs
# ~~~~~~~~~~~~~~~~~~
																# If no error
						if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
							MsgClear G_GLBL_VAR_ARY		# Clear disabled messages
																# Add previously enabled bottles to array
							G_TMP_ARY+=( "${G_TMP_ARY4[@]}" )
																# Turn Host XDG on
							BottleHostXdgEnb G_TMP_ARY G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY GC_XDG_DSKTP_SUBPATH_ARY
						fi
					fi
				;;

# Turn XDG Off
# ------------
				"off")										# Turn Host XDG off
					BottleHostXdgDsb G_TMP_ARY G_GLBL_VAR_ARY GC_STR_ARY GC_XDG_DIR_ARY GC_XDG_SUBPATH_ARY
				;;
				
				*)													# Unrecognized argument
					ErrAdd $WM_ERR_UNK_ARG "Argument: \"${G_TOK_VAR_ARY[$E_TOK_OPT]}\"" G_GLBL_VAR_ARY
				;;
			esac
		fi
	fi

	if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then
																# Refresh host Host XDG
		CustomXdgRefresh "${G_GLBL_VAR_ARY[$E_GLBL_XDG_REFRESH]}" G_GLBL_VAR_ARY
	fi
	DbgPrint "COMMAND xdg: Exiting"
	;;

#
# ------------
# Help Command
# ------------
#
"${GC_STR_ARY[$E_STR_CMD_HELP]}")
																# Verify correct args
	TokParse_TokChk G_TOK_ARY "${GC_STR_ARY[$E_STR_TOKSTR_CMD]}" "${GC_STR_ARY[$E_STR_TOKSTR_OPT]}" G_TMP_TOK_INV
																# Check results
	ArgsRsltChk "$?" "$G_TMP_TOK_INV" G_GLBL_VAR_ARY

	G_TMP_STAT=$?
	if [ $G_TMP_STAT -eq $WM_ERR_NONE ];then		# If arguments okay

		if [ ${G_TOK_VAR_ARY[$E_TOK_OPTF]} -eq 1 ]; then
																# Get usage message for command
			GetHelpStr "${G_TOK_VAR_ARY[$E_TOK_OPT]}" G_GLBL_VAR_ARY[$E_GLBL_STR_HELP] GC_HELP_ARY
			MsgAdd $GC_MSGT_SUCCESS "\n${G_GLBL_VAR_ARY[$E_GLBL_STR_HELP]}" G_GLBL_VAR_ARY
		else
			MsgAdd $GC_MSGT_SUCCESS "\n${GC_HELP_ARY[$E_HLP_ALL]}" G_GLBL_VAR_ARY
		fi
	fi
	;;

#
# --------------------
# Unrecognized Command
# --------------------
#
*)
	DbgPrint "Loading unrecognized command error, Command =\"${G_TOK_VAR_ARY[$E_TOK_CMD]}\""
	ErrAdd $WM_ERR_UNK_CMD "Command: \"${G_TOK_VAR_ARY[$E_TOK_CMD]}\"" G_GLBL_VAR_ARY
	MsgAdd $GC_MSGT_HELP "\n${GC_HELP_ARY[$E_HLP_ALL]}" G_GLBL_VAR_ARY
	;;
esac

																# If error and not unrecognized command
if [[ ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -ne $WM_ERR_NONE && ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} -ne $WM_ERR_UNK_CMD ]]; then
	DbgPrint "Script done, error code detected and it's not an unrecognized command. Loading usage message \"${G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]}\"."
																# Load usage message
	MsgAdd $GC_MSGT_USAGE "${G_GLBL_VAR_ARY[$E_GLBL_STR_USAGE]}" G_GLBL_VAR_ARY
fi
 																# Create and print exit message
DbgPrint "Script done, creating and printing exit message."\"
MsgCreateAndPrint G_GLBL_VAR_ARY GC_ERR_MSG_ARY GC_KF_ERR_MSG_ARY GC_TP_ERR_MSG_ARY
DbgPrint "Script done, exiting."
CleanUpExit ${G_GLBL_VAR_ARY[$E_GLBL_ERR_CODE]} ""
