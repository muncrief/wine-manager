#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                      Multi-Dimensional Array Functions                      *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
#	Description:
#		Functions to manipulate an arbitrary multi-dimensional array (MDA) stored
#		in a one-dimensional array structure.
#
# --------
# Overview
# --------
#
#	Nomenclature
#	~~~~~~~~~~~~
#		MDA
#			Multi-Dimensional Array. A one-dimensional array structure with a
#			multi-dimensional array descriptor block appended to the end.
#
#		ODA
#			One-Dimensional Array.
#
#		DDA
#			Dimension Definition Array. A column first integer array that
#			defines the dimensions for a MDA and its components. For example an
#			array with X, Y, Z dimensions of 5, 4, 3 would be defined by a DDA
#			of (5 4 3). An empty MDA is indicated by a zero size for the last
#			dimension. For example an empty three-dimensional 5 x 4 x ? array
#			DDA would be (5 4 0).
#
#		ADA
#			Address Array. A column first integer array to address a MDA
#			element. For example to address an element at X=2, Y=0, and
#			Z=1 an ADA of (2 0 1) would be used.
#
#		MDADB
#			MDA Descriptor Block.
#
#		Dimension Number
#			The dimension number, starting with X = 0, Y = 1, Z = 2, etc.
#
#		Dimension Size
#			The size of a dimension. For example, the dimension 1 (Y) size of an
#			array with an XYZ of (5 4 2) is 4.
#
#		Dimension Address
#			The address of a dimension. For example, the range of addresses for
#			dimension 0 (X) of an array with an XYZ of (5 4 2) is 0 to 4.
#
#	Architecture
#	~~~~~~~~~~~~
#		An MDA consists of a one-dimensional array of user data stored in
#		row-major order with a fixed length MDA Descriptor Block (MDADB) appended
#		to the end that describes the multi-dimensional array. The MDADB consists
#		of a column first dimension string, number of dimensions, user data size,
#		and MDA ID.
#
#		The MDA ID is an arbitrary number that offers a minimal, and less than
#		perfect, way of assuring a structure is indeed a valid MDA. A header
#		checksum would of course be more desireable, but the performance cost
#		would be too great. The actual ID value is determined by the global
#		constant GC_MDA_ID.
#
#		For example, in the following table indexes 40 to 43 illustrate the MDADB for
#		a three dimensional array with XYZ values of 4x5x2. The user data size is
#		40 elements, and the last index "n" is 43.
#
#						Negative
#			Index		Index		Value		Description
#			-----		--------	-----		-----------
#			0-39		n-4...	???		User data
#			40			n-3		4 5 2		Dimension string
#			41			n-2		3			Number of dimensions
#			42			n-1		40			User data size
#			43			n-0		92317547	MDA ID
#
# Function Flavors
# ~~~~~~~~~~~~~~~~
#		Two flavors of functions are provided, identified by the prefix "MDA_" or
#		"ODA_."
#
#		MDA functions are passed MDA structures as arguments and extract
#		the MDA descriptor as well as performing basic bounds and error checking.
#		Therefore they are easier to use but take longer to execute.
#
#		ODA functions are passed one-dimensional arrays as arguments, and all
#		the MDA paarameters they need can be extracted by the "MDA_GetDesc"
#		function. They perform more extensive bounds and error checking but enable
#		better performance when implementing reptitive operations on a MDA
#		where the repeated extraction of the MDADB or testing of basic parameters
#		is unnecessary.
#
#		For example, "MDA_GetAbsAdr" returns the absolute index for a given array
#		address when passed a MDA, while "ODA_GetAbsAdr" does the same thing when
#		passed a DDA (Dimension Definition Array). This allows multiple indexes to
#		be retrieved with only one DDA extraction. The "MDA_GetDesc" function can
#		be used to get the descriptor block information necessary to use ODA
#		functions, or the user can simply implement their own independent objects
#		instead of using MDA structures.
#
# --------------------------------
# Multi-Dimensional Array Examples
# --------------------------------
#
#	Here are some example MDAs as printed out by the "MDA_Print" funcion.
#
# Two Dimensional Array
# ~~~~~~~~~~~~~~~~~~~~~
#
# One dimension: A row.
# Two dimensions: Pages of 1 dimension (rows) to make rows and columns.
#
# X=5, Y=4
#
#		0		1		2		3		4
#		----	----	----	----	----
#	0|	0		1		2		3		4
#	1|	5		6		7		8		9
#	2|	10		11		12		13		14
#	3|	15		16		17		18		19
#
#
# Three Dimensional Array
# ~~~~~~~~~~~~~~~~~~~~~~~
#
# One dimension: A row.
# Two dimensions: Pages of 1 dimension (rows) to make rows and columns.
# Three dimensions: Pages of 2 dimension (rows and columns) to make pages of rows and columns.
#
# X=5, Y=4, Z=3
#
# Z = 0 --->
#			0		1		2		3		4
#			----	----	----	----	----
#		0|	0		1		2		3		4
#		1|	5		6		7		8		9
#		2|	10		11		12		13		14
#		3|	15		16		17		18		19
#
# Z = 1 --->
#			0		1		2		3		4
#			----	----	----	----	----
#		0|	20		21		22		23		24
#		1|	25		26		27		28		29
#		2|	30		31		32		33		34
#		3|	35		36		37		38		39
#
# Z = 2 --->
#			0		1		2		3		4
#			----	----	----	----	----
#		0|	40		41		42		43		44
#		1|	45		46		47		48		49
#		2|	50		51		52		53		54
#		3|	55		56		57		58		59
#
# Four Dimensional Array
# ~~~~~~~~~~~~~~~~~~~~~~
#
# It's just an array of 3 dimensional arrays.
#
# One dimension: A row.
# Two dimensions: Pages of 1 dimension (rows) to make rows and columns.
# Three dimensions: Pages of 2 dimensions (rows and columns) to make pages of rows and columns.
# Four dimensions: Pages of 3 dimensions (rows and columns and pages) to make pages of pages of rows and columns.
#
# X=5, Y=4, Z=3, W=2
#
# W = 0 --->
#		Z = 0 --->
#				0		1		2		3		4
#				----	----	----	----	----
#			0|	0		1		2		3		4
#			1|	5		6		7		8		9
#			2| 10		11		12		13		14
#			3|	15		16		17		18		19
#
#		Z = 1 --->
#				0		1		2		3		4
#				----	----	----	----	----
#			0|	20		21		22		23		24
#			1|	25		26		27		28		29
#			2|	30		31		32		33		34
#			3|	35		36		37		38		39
#
#		Z = 2 --->
#				0		1		2		3		4
#				----	----	----	----	----
#			0|	40		41		42		43		44
#			1|	45		46		47		48		49
#			2|	50		51		52		53		54
#			3|	55		56		57		58		59
#
# W = 1 --->
#		Z = 0 --->
#				0		1		2		3		4
#				----	----	----	----	----
#			0|	60		61		62		63		64
#			1|	65		66		67		68		69
#			2|	70		71		72		73		74
#			3|	75		76		77		78		79
#
#		Z = 1 --->
#				0		1		2		3		4
#				----	----	----	----	----
#			0|	80		81		82		83		84
#			1|	85		86		87		88		89
#			2|	90		91		92		93		94
#			3|	95		96		97		98		99
#
#		Z = 2 --->
#				0		1		2		3		4
#				----	----	----	----	----
#			0|	100	101	102	103	104
#			1|	105	106	107	108	109
#			2|	110	111	112	113	114
#			3|	115	116	117	118	119
#
#*******************************************************************************
#*                         Create Multi-Dimensional Array                      *
#*******************************************************************************
#
# Function:
#	Creates a MDA from a user supplied ODA and DDA. 
#
# Input:
#	Arg1 = ODA input/MDA return variable name.
#	Arg2 = DDA variable name.
#
# Output:
#	Arg1 = MDA created from ODA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Create ()
{
	local -n __MDACO_l_MDAry="$1"
	local -n __MDACO_l_DDAry="$2"
	local -i l_NumOfDim=0
	local -i l_DataSize=0
	local -i l_iAry=0
	local -i l_FlgZero=0
	local -i l_DimSize=0
	local l_DDAStr
	local -i l_ExitStat=$GC_MDA_ESTAT_OK

	l_NumOfDim=${#__MDACO_l_DDAry[@]}				# Get number of dimensions
	if [[ l_NumOfDim -eq 0 ]]; then					# If none
		l_ExitStat=$GC_MDA_ESTAT_DIM_SIZE			# Set invalid dimension size
	else														# Verify only last dim is 0
		for ((l_iAry=0; l_iAry < l_NumOfDim; l_iAry++))
		do
			l_DimSize=${__MDACO_l_DDAry[l_iAry]}	# Get this dimension size
			if [[ l_DimSize -lt 0 ]]; then			# If less than 0
				l_ExitStat=$GC_MDA_ESTAT_DIM_SIZE	# Set invalid dimension size
				break											# Exit loop
			elif [[ l_DimSize -eq 0 ]]; then			# If 0
				if [[ l_FlgZero -eq 0 ]]; then		# If 0 not detected yet
					l_FlgZero=1								# Set 0 detected
				else											# If 0 already detected
																# Set invalid dimension size
					l_ExitStat=$GC_MDA_ESTAT_DIM_SIZE
					break										# Exit loop
				fi
			fi
		done
	fi
																# If DDA Okay
	if [[ l_ExitStat -eq $GC_MDA_ESTAT_OK ]]; then
																# Get user data size
		ODA_GetUserDataSize __MDACO_l_DDAry l_DataSize
		l_DDAStr="${__MDACO_l_DDAry[@]}"				# Create DDA string
																# If correct user data array size
		if [[ ${#__MDACO_l_MDAry[@]} -eq l_DataSize ]]; then
																# Calc last DB block index
			l_iAry=$(( l_DataSize + GC_MDA_DB_SIZE - 1 ))
																# Add dimension string
			__MDACO_l_MDAry[l_iAry-GC_MDA_DBI_DIMSTR]="$l_DDAStr"
																# Add number of dimensions
			__MDACO_l_MDAry[l_iAry-GC_MDA_DBI_NDIMS]=$l_NumOfDim
																# Add data size
			__MDACO_l_MDAry[l_iAry-GC_MDA_DBI_UDSIZE]=$l_DataSize
																# Add MDA ID
			__MDACO_l_MDAry[l_iAry-GC_MDA_DBI_ID]="$GC_MDA_ID"
		else													# If incorrect user data size
			return $GC_MDA_ESTAT_DATA_SIZE			# Return wrong data size error
		fi
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                Create And Initialize Multi-Dimensional Array                *
#*******************************************************************************
#
# Function:
#	Creates a MDA initialized with the specified value. 
#
# Input:
#	Arg1 = ODA input/MDA return variable name.
#	Arg2 = DDA variable name.
#	Arg3 = Initialization value.
#
# Output:
#	Arg1 = MDA created from ODA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_CreateInit ()
{
	local -n __MDCR_l_MDAry="$1"
	local -n __MDCR_l_DDAry="$2"
	local l_InitVal="$3"
	local -i l_DataSize
																# Get user data size
	ODA_GetUserDataSize __MDCR_l_DDAry l_DataSize

	__MDCR_l_MDAry=()										# Initialize user data
	for ((l_iDim=0; l_iDim < l_DataSize; l_iDim++))
	do
		__MDCR_l_MDAry+=( "$l_InitVal" )
	done

	MDA_Create __MDCR_l_MDAry __MDCR_l_DDAry		# Convert ODA to MDA
	return $?
}

#*******************************************************************************
#*                 Get Multi-Dimensional Descriptor Information                *
#*******************************************************************************
#
# Function:
#	Returns MDA descriptor block information. 
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = DDA return return variable name.
#	Arg3 = Number of dimensions return variable name.
#	Arg4 = User data size return variable name.
#
# Output:
#	Arg2 = DDA.
#	Arg3 = Number of dimensions.
#	Arg4 = User data size.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_GetDesc ()
{
	local -n __MDGINF_l_MDAry="$1"
	local -n __MDGINF_l_DDAry="$2"
	local -n __MDGINF_l_NumOfDim="$3"
	local -n __MDGINF_l_DataSize="$4"
	local	l_DDAStr
	local	-i l_iDim=0
	local	-i l_iDB=${#__MDGINF_l_MDAry[@]}			# Get size of MDA
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
															
	if [[ l_iDB -ge $GC_MDA_DB_SIZE ]]; then		# If MDA at least descriptor block size
		(( l_iDB-- ))										# Base is index of last element
																# If good id
		if [[ "${__MDGINF_l_MDAry[l_iDB-GC_MDA_DBI_ID]}" == "$GC_MDA_ID" ]]; then
																# Get data size
			__MDGINF_l_DataSize=${__MDGINF_l_MDAry[l_iDB-GC_MDA_DBI_UDSIZE]}
																# Get number of dimensions
			__MDGINF_l_NumOfDim=${__MDGINF_l_MDAry[l_iDB-GC_MDA_DBI_NDIMS]}
																# Get DDA string
			l_DDAStr=${__MDGINF_l_MDAry[l_iDB-GC_MDA_DBI_DIMSTR]}
			__MDGINF_l_DDAry=( $l_DDAStr )			# Create DDA
		else
			l_ExitStat=$GC_MDA_ESTAT_NOT_MDA			# Return not a MDA
		fi
	else
		l_ExitStat=$GC_MDA_ESTAT_NOT_MDA				# Return not a MDA
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*        Convert Multi-Dimensional Array To One Dimensional Array             *
#*******************************************************************************
#
# Function:
#	Converts a MDA to a ODA by unsetting all MDA Descriptor Block elements. 
#
# Input:
#	Arg1 = MDA input/ODA return variable name.
#
# Output:
#	Arg1 = ODA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_To_ODA ()
{
	local -n __MDTOOOA_l_MDAry="$1"
																# Get MDA size
	local	-i l_MDArySize=${#__MDTOOOA_l_MDAry[@]}
	local	-i l_i=0
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# If MDA at least descriptor block size
	if [[ l_MDArySize -ge $GC_MDA_DB_SIZE ]]; then
		(( l_MDArySize-- ))								# Point to end of MDADB
																# Unset all MDADB elements
		for ((l_i=l_MDArySize; l_i > l_MDArySize-$GC_MDA_DB_SIZE; l_i--))
		do
			unset __MDTOOOA_l_MDAry[l_i]
		done
	else
		l_ExitStat=$GC_MDA_ESTAT_NOT_MDA				# Return not a MDA
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*    Convert Multi-Dimensional Array To One Dimensional Array With Save       *
#*******************************************************************************
#
# Function:
#	Converts a MDA to a ODA by unsetting all MDA Descriptor Block elements and
#	returns saved descriptor block. 
#
# Input:
#	Arg1 = MDA input/ODA return variable name.
#	Arg2 = MDA Descriptor Block return variable name.
#
# Output:
#	Arg1 = ODA.
#	Arg2 = MDADB.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_To_ODA_Save ()
{
	local -n __MDTOOOAS_l_MDAry="$1"
	local -n __MDTOOOAS_l_DBAry="$2"							
	local	-i l_i=0
	local	-i l_MDArySize
	local	-i l_iDBS
	local -i l_ExitStat=$GC_MDA_ESTAT_OK

	l_MDArySize=${#__MDTOOOAS_l_MDAry[@]}			# Get MDA size
	l_iDBS=$(( $GC_MDA_DB_SIZE-1 ))					# Init descriptor block index
																# If MDA at least descriptor block size
	if [[ l_MDArySize -ge $GC_MDA_DB_SIZE ]]; then
		__MDTOOOAS_l_DBAry=()							# Clear MDADB save array
		(( l_MDArySize-- ))								# Point to end of MDADB
																# Save and unset all MDADB elements
		for ((l_i=l_MDArySize; l_i > l_MDArySize-$GC_MDA_DB_SIZE; l_i--))
		do
			__MDTOOOAS_l_DBAry[l_iDBS--]=${__MDTOOOAS_l_MDAry[l_i]}
			unset __MDTOOOAS_l_MDAry[l_i]
		done
	else
		l_ExitStat=$GC_MDA_ESTAT_NOT_MDA				# Return not a MDA
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*          Convert One Dimensional Array To Multi-Dimensional Array           *
#*******************************************************************************
#
# Function:
#	Converts a ODA to a MDA by appending a MDA Descriptor Block to it. Note that
#	this function is intended to execute as quickly as possible so no error
#	checking is performed. If you wish to create a MDA with error checking use
#	the "MDA_Create" or "MDA_CreateInit" functions. 
#
# Input:
#	Arg1 = ODA input/MDA return variable name.
#	Arg2 = MDA Descriptor Block array variable name.
#
# Output:
#	Arg1 = MDA.
#
# Exit Status:
#	No status returned.
#
function ODA_To_MDA ()
{
	local -n __ODTOMD_l_ODAry="$1"
	local -n __ODTOMD_l_DBAry="$2"
	local	-i l_iDst=${#__ODTOMD_l_ODAry[@]}		# Dest is ODA size
	local	-i l_i

	for ((l_i=0; l_i < $GC_MDA_DB_SIZE; l_i++))	# Append MDADB to ODA
	do
		__ODTOMD_l_ODAry[l_iDst++]=${__ODTOMD_l_DBAry[l_i]}
	done
}

#*******************************************************************************
#*                           Get User Data Size - MDA                          *
#*******************************************************************************
#
# Function:
#	Get user data size using a MDA. 
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = User data size return variable name.
#
# Output:
#	Arg2 = User data size.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_GetUserDataSize ()
{
	local -n __MDGS_l_MDAry="$1"
	local -n __MDGS_l_DataSize="$2"
	local	-i l_iDB
	local	-i l_ExitStat=$GC_MDA_ESTAT_OK

	__MDGS_l_DataSize=0									# Default data size
	l_iDB=${#__MDGS_l_MDAry[@]}						# Get MDA size
	if [[ l_iDB -ge $GC_MDA_DB_SIZE ]]; then		# If MDA at least descriptor block size
		(( l_iDB-- ))										# Base is index of last element
																# If good id
		if [[ "${__MDGS_l_MDAry[l_iDB-GC_MDA_DBI_ID]}" == "$GC_MDA_ID" ]]; then
																# Get user data size
			__MDGS_l_DataSize=${__MDGS_l_MDAry[l_iDB-GC_MDA_DBI_UDSIZE]}
		else
			l_ExitStat=$GC_MDA_ESTAT_NOT_MDA			# Bad ID, return not a MDA
		fi
	else
		l_ExitStat=$GC_MDA_ESTAT_NOT_MDA				# Bad size, return not a MDA
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                            Get User Data Size - ODA                         *
#*******************************************************************************
#
# Function:
#	Get user data size using a DDA.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = User data size return variable name.
#
# Output:
#	Arg2 = User data size.
#
# Exit Status:
#	No status passed.
#
function ODA_GetUserDataSize ()
{
	local -n __ODGS_l_DDAry="$1"
	local -n __ODGS_l_DataSize="$2"
	local -i l_iDim
	local -i l_ArySize

	__ODGS_l_DataSize=0									# Default size

	l_ArySize=${#__ODGS_l_DDAry[@]}					# Get DDA array size
	if [[ $l_ArySize -gt 0 ]]; then					# If not empty
		__ODGS_l_DataSize=${__ODGS_l_DDAry[0]}		# Initialize data size
																# Process all remaining dims
		for ((l_iDim=1; l_iDim < $l_ArySize; l_iDim++))
		do														# Multiply size with previous
			__ODGS_l_DataSize=$(( __ODGS_l_DataSize * ${__ODGS_l_DDAry[l_iDim]} ))
		done
	fi
}

#*******************************************************************************
#*                      Get Absolute Array Address - MDA                       *
#*******************************************************************************
#
# Function:
#	Get absolute one-dimensional array address for a MDA element.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = ADA variable name.
#	Arg3 = Absolute array address return variable name.
#
# Output:
#	Arg3 = Absolute array address.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_GetAbsAdr ()
{
	local -n __MDGI_l_MDAry="$1"
	local -n __MDGI_l_ADAry="$2"
	local -n __MDGI_l_IdxOut="$3"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDGI_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDGI_l_ADAry	# Pad address
																# Use ODA function with info
		ODA_GetAbsAdr l_DDAry __MDGI_l_ADAry __MDGI_l_IdxOut
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                      Get Absolute Array Address - ODA                       *
#*******************************************************************************
#
# Function:
#	Get absolute one-dimensional array address using a DDA.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = ADA variable name.
#	Arg3 = Absolute array address return variable name.
#
# Output:
#	Arg3 = Absolute array address.
#
# Exit Status:
#	No status passed.
#
function ODA_GetAbsAdr ()
{
	local -n __AADR_l_DDAry="$1"
	local -n __AADR_l_ADAry="$2"
	local -n __AADR_l_AbsAdr="$3"
	local -i l_DimElmSize
	local -i l_iDim=1
																# Initial dim size is X size
	local -i __AADR_l_AllDimSize=${__AADR_l_DDAry[0]}
	__AADR_l_AbsAdr=${__AADR_l_ADAry[0]}			# Initial address is X address

	for l_DimElmSize in "${__AADR_l_DDAry[@]:1}"	# Calc rest of dimension sizes
	do															# Add dim size * total dim size so far to address 
		((__AADR_l_AbsAdr += ${__AADR_l_ADAry[l_iDim++]} * __AADR_l_AllDimSize))
		((__AADR_l_AllDimSize *= $l_DimElmSize))	# Calc total dimension size so far
	done
}

#*******************************************************************************
#*                        Check For Valid Address - MDA                        *
#*******************************************************************************
#
# Function:
#	Checks if an ADA is within address bounds of a MDA.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = ADA variable name.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_AdrVfy ()
{
	local -n __MDAAV_l_MDAry="$1"
	local -n __MDAAV_l_ADAry="$2"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAAV_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDAV_l_ADAry			# Pad address
		ODA_AdrVfy l_DDAry __MDAV_l_ADAry			# Use ODA function with info
		l_ExitStat=$?
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                        Check For Valid Address - ODA                        *
#*******************************************************************************
#
# Function:
#	Checks if an ADA is within address bounds of a DDA.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = ADA variable name.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_AdrVfy ()
{
	local -n __ODAAV_l_DDAry="$1"
	local -n __ODAAV_l_ADAry="$2"
	local -i l_DSize
	local -i l_AdrVal
	local -i l_iAry=0
	local -i l_ExitStat=$GC_MDA_ESTAT_OK

	for l_DSize in ${__ODAAV_l_DDAry[@]}			# Get dimension element size
	do
		l_AdrVal=${__ODAAV_l_ADAry[l_iAry]}			# Get address value
																# If it's >= to element size or less than 0
		if [[ l_AdrVal -ge l_DSize || l_AdrVal -lt 0 ]]; then
			l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS		# Set error
			break												# Exit loop
		fi
		(( l_iAry++ ))
	done

	return $l_ExitStat
}

#*******************************************************************************
#*               Address And Dimension Alignment Verify - ODA                  *
#*******************************************************************************
#
# Function:
#	Verifies than an ADA address is within bounds of a DDA, and that the address
#	is aligned with a target dimension number.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = ADA variable name.
#	Arg3 = Align dimension number.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_AdrVfyAlign()
{
	local -n __ODAAVA_l_DDAry="$1"
	local -n __ODAAVA_l_ADAry="$2"
	local -i l_DimNum=$3
	local -i l_NumOfDim
	local -i l_DSize
	local -i l_AdrVal
	local -i l_iAry
	local -i l_ExitStat=$GC_MDA_ESTAT_OK

	l_NumOfDim=${#__ODAAVA_l_DDAry[@]}				# Get number of dimensions
	if [[ l_DimNum -gt $(( $l_NumOfDim - 1 )) ]]; then
		return $GC_MDA_ESTAT_ADR_BOUNDS				# Error if dimension out of bounds
	fi

	for ((l_iAry=0; l_iAry < l_NumOfDim; l_iAry++))
	do
		l_DSize=${__ODAAVA_l_DDAry[l_iAry]}			# Get dimension size
		l_AdrVal=${__ODAAVA_l_ADAry[l_iAry]}		# Get address value
		if [[ l_AdrVal -lt 0 ]]; then					# Error if negative address
			l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS_NEG
			break												# Exit loop

		elif [[ l_AdrVal -gt l_DSize-1 ]]; then 	# If address greater than dimension size
			l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS		# Set error
			break												# Exit loop

		else													# If less than target elm and not 0
			if [[ l_iAry -lt l_DimNum && l_AdrVal -ne 0 ]]; then
			
				l_ExitStat=$GC_MDA_ESTAT_ADR_ALIGN	# Set alignment error
				break											# Exit loop
			fi
		fi
	done

	return $l_ExitStat
}

#*******************************************************************************
#*           Address And Dimension Alignment And Range Verify - ODA            *
#*******************************************************************************
#
# Function:
#	Verifies than an ADA address is within bounds of a DDA, and that the address
#	is aligned with a target dimension number and address range.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = ADA variable name.
#	Arg3 = Align dimension number.
#	Arg4 = Align dimension address range.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_AdrVfyAlignRange()
{
	local -n __ODAAVAR_l_DDAry="$1"
	local -n __ODAAVAR_l_ADAry="$2"
	local -i l_DimNum=$3
	local -i l_DimAdrRange=$4
	local -i l_NumOfDim
	local -i l_AdrMax
	local -i l_AdrVal
	local -i l_iAry
	local -i l_ExitStat=$GC_MDA_ESTAT_OK

	l_NumOfDim=${#__ODAAVAR_l_DDAry[@]}				# Get number of dimensions
	if [[ l_DimNum -gt $(( $l_NumOfDim - 1 )) ]]; then
		return $GC_MDA_ESTAT_DIM_NUM					# Error if dimension out of bounds
	fi

	for ((l_iAry=0; l_iAry < l_NumOfDim; l_iAry++))
	do
																# Get maximum address
		l_AdrMax=$(( ${__ODAAVAR_l_DDAry[l_iAry]}-1 ))
		l_AdrVal=${__ODAAVAR_l_ADAry[l_iAry]}		# Get address value
		if [[ l_AdrVal -lt 0 ]]; then					# Error if negative address
			l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS_NEG
			break												# Exit loop

		elif [[ l_iAry -eq l_DimNum ]]; then	# If target element
																# If out of range
			if [[ l_AdrVal -gt l_AdrMax  || l_AdrVal+l_DimAdrRange-1 -gt l_AdrMax ]]; then
																# If low element out of bounds
				if [[ l_AdrVal -gt l_AdrMax ]]; then
					l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS_LOW
				else											# If high element out of bounds
					l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS_HI
				fi
				break											# Exit loop
			fi

		elif [[ l_AdrVal -gt l_AdrMax ]]; then 	# If address greater than dimension size
			l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS		# Set error
			break												# Exit loop
																
		else													# If less than target elm and not 0
			if [[ l_iAry -lt l_DimNum && l_AdrVal -ne 0 ]]; then
				l_ExitStat=$GC_MDA_ESTAT_ADR_ALIGN	# Set alignment error
				break											# Exit loop
			fi
		fi
	done

	return $l_ExitStat
}

#*******************************************************************************
#*                         Dimension Address Verify - ODA                      *
#*******************************************************************************
#
# Function:
#	Verifies than a dimension number and its address are valid. 
#
# Input:
#	Arg1 = Dimension number.
#	Arg2 = Number of dimensions.
#	Arg3 = Dimension address.
#	Arg4 = Dimension maximum address.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_DimAdrVfy()
{
	local -i l_DimNum=$1
	local -i l_NumOfDim=$2
	local -i l_DimAdr=$3
	local -i l_DimAdrMax=$4
	local -i l_ExitStat=$GC_MDA_ESTAT_OK

	if [[ l_DimNum -lt 0 || l_DimNum -ge l_NumOfDim ]]; then
		l_ExitStat=$GC_MDA_ESTAT_DIM_NUM				# Error if dimension doesn't exist

	elif [[ l_DimAdr -lt 0 || l_DimAdr -gt $l_DimAdrMax ]]; then
		l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS			# Error if dimension address out of bounds
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                     Dimension Address Range Verify - ODA                    *
#*******************************************************************************
#
# Function:
#	Verifies than a dimension number and its address are valid. 
#
# Input:
#	Arg1 = Dimension number.
#	Arg2 = Number of dimensions.
#	Arg3 = Dimension address.
#	Arg4 = Dimension maximum address.
#	Arg5 = Dimension address range.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_DimAdrVfyRange()
{
	local -i l_DimNum=$1
	local -i l_NumOfDim=$2
	local -i l_DimAdr=$3
	local -i l_DimAdrMax=$4
	local -i l_DimRange=$5
	local -i l_ExitStat=$GC_MDA_ESTAT_OK

	if [[ l_DimNum -lt 0 || l_DimNum -ge l_NumOfDim ]]; then
		l_ExitStat=$GC_MDA_ESTAT_DIM_NUM				# Error if dimension doesn't exist

	elif [[ l_DimAdr -lt 0 || l_DimAdr -gt $l_DimAdrMax || l_DimAdr+l_DimRange-1 -gt l_DimAdrMax ]]; then
		l_ExitStat=$GC_MDA_ESTAT_ADR_BOUNDS			# Error if dimension address out of bounds
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                        Get Dimension Data Size - MDA                        *
#*******************************************************************************
#
# Function:
#	Get size of MDA dimension data using a MDA.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = Dimension number.
#	Arg3 = Dimension data size return variable name.
#
# Output:
#	Arg3 = Dimension data size.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_GetDimDataSize ()
{
	local -n __MDGDS_l_MDAry="$1"
	local l_DimNum="$2"
	local -n __MDGDS_l_SizeRet="$3"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDGDS_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
																# Use ODA function with info
		ODA_GetDimDataSize l_DDAry $l_DimNum __MDGDS_l_SizeRet
		l_ExitStat=$?
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}


#*******************************************************************************
#*                         Get Dimension Data Size - ODA                       *
#*******************************************************************************
#
# Function:
#	Get size of MDA dimension data using a DDA.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = Dimension number.
#	Arg3 = Dimension data size return variable name.
#
# Output:
#	Arg3 = Dimension data size.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_GetDimDataSize ()
{
	local -n __ODGDS_l_DDAry="$1"
	local -i l_DimNum=$2
	local -n __ODGDS_l_SizeRet="$3"
	local	-i l_iDim
	local	-i l_ExitStat=$GC_MDA_ESTAT_OK
																# If dim index not larger than DDA index
	if [[ l_DimNum -lt ${#__ODGDS_l_DDAry[@]} ]]; then

		__ODGDS_l_SizeRet=${__ODGDS_l_DDAry[0]}	# Initial size is X dim size
																# Read remaining values from array
		for ((l_iDim=1; l_iDim <= l_DimNum; l_iDim++))
		do														# Multiply size with previous
			__ODGDS_l_SizeRet=$(( __ODGDS_l_SizeRet * ${__ODGDS_l_DDAry[l_iDim]} ))
		done
	else														# If dim index out of range
		__ODGDS_l_SizeRet=0								# Size is 0
		l_ExitStat=$GC_MDA_ESTAT_DIM_NUM				# Return invalid dim index error
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                   Get Dimension Element Data Size - MDA                     *
#*******************************************************************************
#
# Function:
#	Get size of MDA dimension element data using a MDA.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = Dimension number.
#	Arg3 = Dimension element data size return variable name.
#
# Output:
#	Arg3 = Dimension element data size.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_GetDimElmDataSize ()
{
	local -n __MDGDES_l_MDAry="$1"
	local -i l_DimNum=$2
	local -n __MDGDES_l_SizeRet="$3"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDGDES_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
																# Use ODA function with info
		ODA_GetDimElmDataSize l_DDAry $l_DimNum __MDGDES_l_SizeRet
		l_ExitStat=$?
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                   Get Dimension Element Data Size - ODA                     *
#*******************************************************************************
#
# Function:
#	Get size of MDA dimension element data using a DDA.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = Dimension number.
#	Arg3 = Dimension element data size return variable name.
#
# Output:
#	Arg3 = Dimension element data size.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_GetDimElmDataSize ()
{
	local -n __ODGDES_l_DDAry="$1"
	local -i l_DimNum=$2
	local -n __ODGDES_l_SizeRet="$3"
	local -a l_DDAryCpy
	local	-i l_iDim=0
	local	-i l_DimSize
	local -i l_LastIdx
	local	-i l_ExitStat=$GC_MDA_ESTAT_OK

	l_LastIdx=$(( ${#__ODGDES_l_DDAry[@]} - 1 ))	# Last index is end of array
	l_DDAryCpy=( "${__ODGDES_l_DDAry[@]}" )		# Copy DDA for temp change
																# If empty array
	if [[ ${l_DDAryCpy[l_LastIdx]} -eq 0 ]]; then
		l_DDAryCpy[l_LastIdx]=1							# Set dimension size to 1 for calc
	fi
	__ODGDES_l_SizeRet=1									# Initialize size multiplier (size of single X element)
																# Process remaining dimensions
	for ((l_iDim=0; l_iDim < l_DimNum; l_iDim++))
	do															# Multiply with previous
		if [[ l_iDim -gt l_LastIdx ]]; then			# If target dim beyond last dim
			l_DimSize=1										# Fake it with 1
		else
			l_DimSize=${l_DDAryCpy[l_iDim]}			# Otherwise use real dim size
		fi
		__ODGDES_l_SizeRet=$(( __ODGDES_l_SizeRet * l_DimSize ))
	done

	return $l_ExitStat
}

#*******************************************************************************
#*                                  Pad Address - ODA                          *
#*******************************************************************************
#
# Function:
#	Pads an address with zeroes so it's the same length as the target.
#
# Input:
#	Arg1 = Target ADA variable name.
#	Arg2 = Pad ADA variable name.
#
# Output:
#	Arg2 = Padded ADA.
#
# Exit Status:
#	No status passed.
#
function ODA_PadAdr ()
{
	local -n __ODPA_l_AdrTarg="$1"
	local -n __ODPA_l_AdrPad="$2"
	local -i l_AdrLenTarg=0
	local -i l_AdrLenPad=0
	local -i l_iAry=0
	
	l_AdrLenTarg=${#__ODPA_l_AdrTarg[@]}
	l_AdrLenPad=${#__ODPA_l_AdrPad[@]}

	if [ $l_AdrLenTarg -gt $l_AdrLenPad ]; then	# If target longer than pad address
																# Add 0s to pad address
		for ((l_iAry=l_AdrLenPad; l_iAry < l_AdrLenTarg; l_iAry++))
		do
			__ODPA_l_AdrPad+=( 0 )
		done
	fi
}

#*******************************************************************************
#*                  Create DDA String from Dimension Number                    *
#*******************************************************************************
#
# Function:
#	Creates the DDA for a dimension from a DDA, element index, and number
#	of elements.
#
# Input:
#	Arg1 = Source DDA variable name.
#	Arg1 = Dimension number.
#	Arg2 = Number of elements
#	Arg3 = Destination DDA return variable name.
#
# Output:
#	Arg3 = Dimension number DDA.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_DimToDDA ()
{
	local -n __ODADIMDDA_l_DDArySrc="$1"
	local -i l_DimNum=$2
	local -i l_NumOfElm=$3
	local -n __ODADIMDDA_l_DDAryDst="$4"
	local -i l_iDim
	local -i l_DSize
	local -i l_FlgDimFound=0
	local -a l_DDAryOut=()
	local	-i l_ExitStat=$GC_MDA_ESTAT_OK
																# If dimension exists
	if [[ l_DimNum -lt ${#__ODADIMDDA_l_DDArySrc[@]} ]]; then
		for ((l_iDim=0; l_iDim < l_DimNum; l_iDim++))
		do														# Get dimension size
			l_DSize=${__ODADIMDDA_l_DDArySrc[l_iDim]}
			if [ $l_DSize -gt 0 ]; then				# If we found first valid dim
				l_FlgDimFound=1							# Set dimension found
			fi
																# Transfer dim to DDA
			__ODADIMDDA_l_DDAryDst[l_iDim]=$l_DSize
		done

		if [ $l_FlgDimFound -eq 1 ]; then			# If dim found
																# Last dimension size is number of elements
			__ODADIMDDA_l_DDAryDst[l_iDim]=$l_NumOfElm
		else													# If no dim
			__ODADIMDDA_l_DDAryDst=( $l_NumOfElm )	# Dim index is 0, set X only DDA
		fi
	else
		l_ExitStat=$GC_MDA_ESTAT_DIM_NUM
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                         Increment Array Address - MDA                       *
#*******************************************************************************
#
# Function:
#	Increments a MDA address.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = ADA input/return variable name.
#
# Output:
#	Arg2 = Incremented ADA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Inc ()
{
	local -n __MDAINC_l_MDAry="$1"
	local -n __MDAINC_l_ADAry="$2"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAINC_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDAINC_l_ADAry			# Pad address
																# Use ODA function with info
		ODA_Inc l_DDAry $l_NumOfDim __MDAINC_l_ADAry
	else
 		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                         Increment Array Address - ODA                       *
#*******************************************************************************
#
# Function:
#	Increments a MDA address.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = Number of dimensions.
#	Arg3 = ADA input/return variable name.
#
# Output:
#	Arg3 = Incremented ADA.
#
# Exit Status:
#	No status passed.
#
function ODA_Inc ()
{
	local -n __ODAINC_l_DDAry="$1"
	local -i l_NumOfDim=$2
	local -n __ODAINC_l_ADAry="$3"
	local -i l_iDim=0

	while [[ l_iDim -lt l_NumOfDim ]]				# Inc all dimension addresses
	do
		(( __ODAINC_l_ADAry[l_iDim]++ ))				# Increment address
																# If not end of this dimension
		if [[ ${__ODAINC_l_ADAry[l_iDim]} -lt $(( ${__ODAINC_l_DDAry[l_iDim]} )) ]]; then
			break												# Exit loop
		else													# Otherwise if end of dimension
			__ODAINC_l_ADAry[l_iDim++]=0				# Reset dimension address
		fi
	done
}

#*******************************************************************************
#*                        Decrement Array Address - MDA                        *
#*******************************************************************************
#
# Function:
#	Decrements a MDA address.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = ADA input/return variable name.
#
# Output:
#	Arg2 = Decremented ADA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Dec ()
{
	local -n __MDADEC_l_MDAry="$1"
	local -n __MDADEC_l_ADAry="$2"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDADEC_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDADEC_l_ADAry			# Pad address
																# Use ODA function with info
		ODA_Dec l_DDAry $l_NumOfDim __MDADEC_l_ADAry
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                        Decrement Array Address - ODA                        *
#*******************************************************************************
#
# Function:
#	Decrements a MDA address.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = Number of dimensions.
#	Arg3 = ADA input/return variable name.
#
# Output:
#	Arg3 = Decremented ADA.
#
# Exit Status:
#	No status passed.
#
function ODA_Dec ()
{
	local -n __ODADEC_l_DDAry="$1"
	local -i l_NumOfDim=$2
	local -n __ODADEC_l_ADAry="$3"
	local -i l_iDim=0

	while [[ l_iDim -lt l_NumOfDim ]]				# Inc all dimension addresses
	do
		(( __ODADEC_l_ADAry[l_iDim]-- ))				# Decrement address
																# If not beginning of dimension
		if [ ${__ODADEC_l_ADAry[l_iDim]} -gt -1 ]; then
			break												# Exit loop
		else													# Otherwise it's beginning of dimension
																# Reset dimension address
			__ODADEC_l_ADAry[l_iDim++]=$((${__ODADEC_l_DDAry[l_iDim]} - 1))
		fi
	done
}

#*******************************************************************************
#*            Increment Array Address With Information Return - MDA            *
#*******************************************************************************
#
# Function:
#	Increments a MDA address and returns information about incremented addresses.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = ADA input/return variable name.
#	Arg3 = Increment Information Array return variable name.
#	Arg4 = Highest dimension number incremented return variable name.
#	Arg5 = Wrap around flag return variable name.
#
# Output:
#	Arg2 = Incremented ADA.
#	Arg3 = Increment Information Array. This is the same size as the
#			 Address Array. Each index contains one of the status codes below for
#			 its corresponding dimension in the Address Array: 
#			   
#				GC_MDA_INC_NONE		# No increment
#				GC_MDA_INC				# Normal increment
#				GC_MDA_INC_RST			# Increment reset
#
#	Arg4 = Highest dimension number incremented.
#	Arg5 = Wrap around flag.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_IncInfo ()
{
	local -n __MDAINC_l_MDAry="$1"
	local -n __MDAINC_l_ADAry="$2"
	local -n __MDAINC_l_InfAry="$3"
	local -n __MDAINC_l_HiDimInc="$4"
	local -n __MDAINC_l_FlgWrap="$5"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAINC_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDAINC_l_ADAry			# Pad address
																# Use ODA function with info
		ODA_IncInfo l_DDAry $l_NumOfDim __MDAINC_l_ADAry __MDAINC_l_InfAry __MDAINC_l_HiDimInc __MDAINC_l_FlgWrap
	else
 		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*            Increment Array Address With Information Return - ODA            *
#*******************************************************************************
#
# Function:
#	Increments a MDA address and returns information about incremented addresses.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = Number of dimensions variable name.
#	Arg3 = ADA input/return variable name.
#	Arg4 = Increment Information Array return variable name.
#	Arg5 = Highest dimension number incremented return variable name.
#	Arg6 = Wrap around flag return variable name.
#
# Output:
#	Arg3 = Incremented ADA.
#	Arg4 = Return Increment Information Array. This is the same size as the
#			 Address Array. Each element contains one of the status codes below for
#			 its corresponding dimension in the Address Array: 
#			   
#				GC_MDA_INC_NONE		# No increment
#				GC_MDA_INC				# Normal increment
#				GC_MDA_INC_RST			# Increment reset
#
#	Arg5 = Highest dimension incremented index.
#	Arg6 = Return wrap around flag.
#
# Exit Status:
#	No status passed.
#
function ODA_IncInfo ()
{
	local -n __ODAINCI_l_DDAry="$1"
	local -i __ODAINCI_l_NumOfDim=$2
	local -n __ODAINCI_l_ADAry="$3"
	local -n __ODAINCI_l_InfAry="$4"
	local -n __ODAINCI_l_HiDimInc="$5"
	local -n __ODAINCI_l_FlgWrap="$6"
	local -i l_iDim

	__ODAINCI_l_FlgWrap=0								# Clear wrap around flag
																# Inc dimensions
	for ((l_iDim=0; l_iDim < $__ODAINCI_l_NumOfDim; l_iDim++))
	do
		(( __ODAINCI_l_ADAry[l_iDim]++ ))			# Increment address
											 					# If not end of this dimension
		if [[ ${__ODAINCI_l_ADAry[l_iDim]} -lt ${__ODAINCI_l_DDAry[l_iDim]} ]]; then
															
			__ODAINCI_l_InfAry[l_iDim]=$GC_MDA_INC	# Set normal inc info
			break												# Exit loop
		else													# Otherwise it's end of dimension
			__ODAINCI_l_ADAry[l_iDim]=0				# Reset dimension address
																# Set reset info
			__ODAINCI_l_InfAry[l_iDim]=$GC_MDA_INC_RST
																# If last dimension
			if [[ l_iDim -eq __ODAINCI_l_NumOfDim-1 ]]; then
				__ODAINCI_l_FlgWrap=1					# Set wrap around flag
				break											# Exit loop
			fi
		fi
	done

	__ODAINCI_l_HiDimInc=$l_iDim						# Return highest dimension incremented
																# Clear remaining info array
	for ((l_iDim++; l_iDim < $__ODAINCI_l_NumOfDim; l_iDim++))
	do
		__ODAINCI_l_InfAry[l_iDim]=$GC_MDA_INC_NONE
	done
}

#*******************************************************************************
#*            Decrement Array Address With Information Return - MDA            *
#*******************************************************************************
#
# Function:
#	Decrements a MDA address and returns information about decremented addresses.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = ADA input/return variable name.
#	Arg3 = Decrement Information Array return variable name.
#	Arg4 = Highest dimension number decremented return variable name.
#	Arg5 = Wrap around flag return variable name.
#
# Output:
#	Arg2 = Decremented ADA.
#	Arg3 = Return Decrement Information Array. This is the same size as the
#			 Address Array. Each element contains one of the status codes below for
#			 its corresponding dimension in the Address Array: 
#
#				GC_MDA_DEC_NONE		# No decrement
#				GC_MDA_DEC				# Normal decrement
#				GC_MDA_DEC_RST			# Decrement reset
#
#	Arg4 = Highest dimension number decremented.
#	Arg5 = Wrap around flag.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_DecInfo ()
{
	local -n __MDADEC_l_MDAry="$1"
	local -n __MDADEC_l_ADAry="$2"
	local -n __MDADEC_l_InfAry="$3"
	local -n __MDADEC_l_HiDimDec="$4"
	local -n __MDADEC_l_FlgWrap="$5"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDADEC_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDADEC_l_ADAry			# Pad address
																# Use ODA function with info
		ODA_DecInfo l_DDAry $l_NumOfDim __MDADEC_l_ADAry __MDADEC_l_InfAry __MDADEC_l_HiDimDec __MDADEC_l_FlgWrap
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*            Decrement Array Address With Information Return - ODA            *
#*******************************************************************************
#
# Function:
#	Decrements a MDA address and returns information about decremented addresses.
#
# Input:
#	Arg1 = DDA variable name.
#	Arg2 = Nmber of dimensions variable name.
#	Arg3 = ADA input/return variable name.
#	Arg4 = Decrement Information Array return variable name.
#	Arg5 = Highest dimension number decremented return variable name.
#	Arg6 = Wrap around flag return variable name.
#
# Output:
#	Arg3 = Decremented ADA.
#	Arg4 = Return Decrement Information Array. This is the same size as the
#			 Address Array. Each element contains one of the status codes below for
#			 its corresponding dimension in the Address Array: 
#			   
#				GC_MDA_DEC_NONE		# No decrement
#				GC_MDA_DEC				# Normal decrement
#				GC_MDA_DEC_RST			# Decrement reset
#
#	Arg5 = Highest dimension number decremented.
#	Arg6 = Wrap around flag.
#
# Exit Status:
#	No status passed.
#
function ODA_DecInfo ()
{
	local -n __ODADEC_l_DDAry="$1"
	local -i __ODADEC_l_NumOfDim=$2
	local -n __ODADEC_l_ADAry="$3"
	local -n __ODADEC_l_InfAry="$4"
	local -n __ODADEC_l_HiDimDec="$5"
	local -n __ODADEC_l_FlgWrap="$6"
	local -i l_iDim

	__ODADEC_l_FlgWrap=0									# Clear wrap around flag
																# Dec all dimension addresses
	for ((l_iDim=0; l_iDim < $__ODADEC_l_NumOfDim; l_iDim++))
	do
		(( __ODADEC_l_ADAry[l_iDim]-- ))				# Decrement address
																# If address not -1
		if [ ${__ODADEC_l_ADAry[l_iDim]} -ne -1 ]; then
																# Set normal dec info
			__ODADEC_l_InfAry[l_iDim]=$GC_MDA_DEC
			break												# Exit loop
		else													# Otherwise it's end of dimension
																# Reset dimension address
			__ODADEC_l_ADAry[l_iDim]=$((${__ODADEC_l_DDAry[l_iDim]} - 1))
																# Set reset info
			__ODADEC_l_InfAry[l_iDim]=$GC_MDA_DEC_RST
																# If last dimension
			if [[ l_iDim -eq __ODADEC_l_NumOfDim-1 ]]; then
				__ODADEC_l_FlgWrap=1						# Set wrap around flag
				break											# Exit loop
			fi
		fi
	done

	__ODADEC_l_HiDimDec=$l_iDim						# Return highest dimension decremented
																# Clear remaining info array
	for ((l_iDim++; l_iDim < $__ODADEC_l_NumOfDim; l_iDim++))
	do
		__ODADEC_l_InfAry[l_iDim]=$GC_MDA_INC_NONE
	done
}

#*******************************************************************************
#*                      Read From MDA To Variable - MDA                        *
#*******************************************************************************
#
# Function:
#	Read a value from a source MDA.
#
# Input:
#	Arg1 = Source MDA variable name.
#	Arg2 = Read ADA variable name.
#	Arg3 = Destination read return variable name.
#
# Output:
#	Arg3 = Read value.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Rd ()
{
	local -n __MDARD_l_MDAry="$1"
	local -n __MDARD_l_ADAry="$2"
	local -n __MDARD_l_RdVal="$3"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDARD_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDARD_l_ADAry			# Pad address
																# Use ODA function with info
		ODA_Rd __MDARD_l_MDAry l_DDAry __MDARD_l_ADAry __MDARD_l_RdVal
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                      Read From MDA To Variable - ODA                        *
#*******************************************************************************
#
# Function:
#	Read a value from a source MDA.
#
# Input:
#	Arg1 = Source ODA variable name.
#	Arg2 = Source DDA variable name.
#	Arg3 = Read ADA variable name.
#	Arg4 = Destination read return variable name.
#
# Output:
#	Arg4 = Read value.
#
# Exit Status:
#	No status passed.
#
function ODA_Rd ()
{
	local -n __ODARD_l_ODArySrc="$1"
	local -n __ODARD_l_DDArySrc="$2"
	local -n __ODARD_l_ADAryRd="$3"
	local -n __ODARD_l_RdVal="$4"
	local -i l_AbsAryIdx=0
																# Get absolute array index
	ODA_GetAbsAdr __ODARD_l_DDArySrc __ODARD_l_ADAryRd l_AbsAryIdx
																# Read value from element
	__ODARD_l_RdVal="${__ODARD_l_ODArySrc[l_AbsAryIdx]}"

	return $GC_MDA_ESTAT_OK
}

#*******************************************************************************
#*                         Read From MDA To Array - MDA                        *
#*******************************************************************************
#
# Function:
#	Read from a source MDA to a destination ODA. The number of values to be read
#	is specified by an integer parameter.
#
# Input:
#	Arg1 = Source MDA variable name.
#	Arg2 = Read address ADA variable name.
#	Arg3 = Read size.
#	Arg4 = Destination ODA return variable name.
#
# Output:
#	Arg4 = Read data ODA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_RdAry ()
{
	local -n __MDARM_l_MDArySrc="$1"
	local -n __MDARM_l_ADAryRd="$2"
	local -i l_RdSize="$3"
	local -n __MDARM_l_ODAryDst="$4"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDARM_l_MDArySrc l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDARM_l_ADAryRd		# Pad address
																# Use ODA function with info
		ODA_RdAry __MDARM_l_MDArySrc l_DDAry __MDARM_l_ADAryRd $l_RdSize __MDARM_l_ODAryDst
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                         Read From MDA To Array - ODA                        *
#*******************************************************************************
#
# Function:
#	Read from a source ODA to a destination ODA. The number of values to be read
#	is specified by an integer parameter.
#
# Input:
#	Arg1 = Source ODA variable name.
#	Arg2 = Source DDA variable name.
#	Arg3 = Read address ADA variable name.
#	Arg4 = Read size.
#	Arg5 = Destination ODA return variable name.
#
# Output:
#	Arg5 = Read data ODA.
#
# Exit Status:
#	No status passed.
#
function ODA_RdAry ()
{
	local -n __ODARM_l_ODArySrc="$1"
	local -n __ODARM_l_DDArySrc="$2"
	local -n __ODARM_l_ADAryRd="$3"
	local -i l_RdSize="$4"
	local -n __ODARM_l_ODAryDst="$5"
	local -i l_AbsAryIdx
	local -i l_iSrc
	local -i l_iDst=0
																# Get absolute array read index
	ODA_GetAbsAdr __ODARM_l_DDArySrc __ODARM_l_ADAryRd l_AbsAryIdx
	l_RdSize=$(( l_RdSize + l_AbsAryIdx ))			# Calc read offset
																# Read values from array
	for ((l_iSrc=l_AbsAryIdx; l_iSrc < l_RdSize; l_iSrc++))
	do
		__ODARM_l_ODAryDst[l_iDst]="${__ODARM_l_ODArySrc[l_iSrc]}"
		(( l_iDst++ ))
	done

	return $GC_MDA_ESTAT_OK
}

#*******************************************************************************
#*                         Write Variable To MDA - MDA                         *
#*******************************************************************************
#
# Function:
#	Writes a value to a destination MDA.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = Write ADA variable name.
#	Arg3 = Input write value.
#
# Output:
#	Arg1 = MDA with write value.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Wr ()
{
	local -n __MDAWR_l_MDAry="$1"
	local -n __MDAWR_l_ADAry="$2"
	local l_WrVal="$3"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAWR_l_MDAry l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDAWR_l_ADAry			# Pad address
																# Use ODA function with info
		ODA_Wr __MDAWR_l_MDAry l_DDAry __MDAWR_l_ADAry "$l_WrVal"
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                         Write Variable To MDA - ODA                         *
#*******************************************************************************
#
# Function:
#	Writes a value to a destination MDA using a DDA.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = DDA variable name.
#	Arg3 = Write ADA variable name.
#	Arg4 = Input write value.
#
# Output:
#	Arg1 = MDA with write value.
#
# Exit Status:
#	No status passed.
#
function ODA_Wr ()
{
	local -n __ODAWR_l_ODAry="$1"
	local -n __ODAWR_l_DDAry="$2"
	local -n __ODAWR_l_ADAry="$3"
	local l_WrVal="$4"
	local -i l_AbsAdr
																# Get absolute array address
	ODA_GetAbsAdr __ODAWR_l_DDAry __ODAWR_l_ADAry l_AbsAdr
	__ODAWR_l_ODAry[l_AbsAdr]="$l_WrVal"			# Write value to element
}

#*******************************************************************************
#*                           Write ODA To MDA - MDA                            *
#*******************************************************************************
#
# Function:
#	Write from a source ODA to a destination MDA. The number of values to be
#	written is specified by an integer parameter.
#
# Input:
#	Arg1 = Destination MDA return variable name.
#	Arg2 = Write address ADA variable name.
#	Arg3 = Write size.
#	Arg4 = Source ODA variable name.
#
# Output:
#	Arg1 = MDA with write values.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_WrODA ()
{
	local -n __MDAWM_l_MDAryDst="$1"
	local -n __MDAWM_l_ADAryWr="$2"
	local -i l_WrSize=$3
	local -n __MDAWM_l_ODArySrc="$4"
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAWM_l_MDAryDst l_DDAry l_NumOfDim l_DataSize; then
		ODA_PadAdr l_DDAry __MDAWM_l_ADAryWr		# Pad address
																# Use ODA function with info
		ODA_WrODA __MDAWM_l_MDAryDst l_DDAry __MDAWM_l_ADAryWr $l_WrSize __MDAWM_l_ODArySrc
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                           Write ODA To MDA - ODA                            *
#*******************************************************************************
#
# Function:
#	Write from a source ODA to a destination ODA. The number of values to be
#	written is specified by an integer parameter.
#
# Input:
#	Arg1 = Destination ODA return variable name.
#	Arg2 = Destination DDA variable name.
#	Arg3 = Write address ADA variable name.
#	Arg4 = Write size.
#	Arg5 = Source ODA variable name.
#
# Output:
#	Arg1 = ODA with write values.
#
# Exit Status:
#	No status passed.
#
function ODA_WrODA ()
{
	local -n __ODAWM_l_ODAryDst="$1"
	local -n __ODAWM_l_DDAryDst="$2"
	local -n __ODAWM_l_ADAryWr="$3"
	local -i l_WrSize=$4
	local -n __ODAWM_l_ODArySrc="$5"
	local -i l_AbsAryIdx=0
	local -i l_iDst
	local -i l_iSrc=0
																# Get absolute array write index
	ODA_GetAbsAdr __ODAWM_l_DDAryDst __ODAWM_l_ADAryWr l_AbsAryIdx
	l_WrSize=$(( l_WrSize + l_AbsAryIdx ))			# Calc write offset
	l_iSrc=0													# Init read index
																# Write values to array
	for ((l_iDst=l_AbsAryIdx; l_iDst < l_WrSize; l_iDst++))
	do
		__ODAWM_l_ODAryDst[l_iDst]="${__ODAWM_l_ODArySrc[l_iSrc]}"
		(( l_iSrc++))										# Inc read index
	done

	return $GC_MDA_ESTAT_OK
}

#*******************************************************************************
#*                            Copy MDA To MDA - MDA                            *
#*******************************************************************************
#
# Function:
#	Copies all or part of a source MDA to a destination MDA. The base for the MDA
#	write is specified by a write ADA, and the base for the MDA read is specified
#	by a read ADA. The element dimension number and number of elements to be
#	copied are specified by integer arguments.
#
# Input:
#	Arg1 = Source MDA variable name.
#	Arg2 = Read address ADA variable name.
#	Arg3 = Destination MDA variable name.
#	Arg4 = Write address ADA variable name.
#	Arg5 = Dimension number.
#	Arg6 = Number of elements to be copied.
#
# Output:
#	Arg3 = MDA with write values.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Copy ()
{
	local -n __MDAWRE_l_MDArySrc="$1"
	local -n __MDAWRE_l_ADAryRd="$2"
	local -n __MDAWRE_l_MDAryDst="$3"
	local -n __MDAWRE_l_ADAryWr="$4"
	local -i l_DimNum=$5
	local -i l_NumOfElm=$6
	local -a l_DDAry
	local -i l_NumOfDim
	local	-i l_DataSize
	local -a l_DDArySrc
	local	-i l_DataSizeSrc
	local -i l_NumOfDimSrc
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAWRE_l_MDAryDst l_DDAry l_NumOfDim l_DataSize; then
		if MDA_GetDesc __MDAWRE_l_MDArySrc l_DDArySrc l_NumOfDimSrc l_DataSizeSrc; then
			ODA_PadAdr l_DDAry __MDAWRE_l_ADAryWr	# Pad destination address
																# Pad source address
			ODA_PadAdr l_DDArySrc __MDAWRE_l_ADAryRd
																# Use ODA function with info
			ODA_Copy __MDAWRE_l_MDArySrc l_DDArySrc __MDAWRE_l_ADAryRd __MDAWRE_l_MDAryDst l_DDAry __MDAWRE_l_ADAryWr $l_DimNum  $l_NumOfElm
			l_ExitStat=$?
		else
			l_ExitStat=$?
		fi
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                            Copy MDA To MDA - ODA                            *
#*******************************************************************************
#
# Function:
#	Copies all or part of a source ODA to a destination ODA given their
#	respective DDAs. The base for the ODA read is specified by a read ADA, and
#	the base for the ODA write is specified by a write ADA. The dimension number
#	and number of elements to be copied are specified by integer arguments.
# 
# Input:
#	Arg1 = Source ODA variable name.
#	Arg2 = Source DDA variable name.
#	Arg3 = Read address ADA variable name.
#	Arg4 = Destination ODA variable name.
#	Arg5 = Destination DDA variable name.
#	Arg6 = Write address ADA variable name.
#	Arg7 = Dimension number.
#	Arg8 = Number of elements to be copied.
#
# Output:
#	Arg3 = ODA with write values.
#
# Exit Status:
#	No status passed.
#
function ODA_Copy ()
{
	local -n __ODAWRE_l_ODArySrc="$1"
	local -n __ODAWRE_l_DDArySrc="$2"
	local -n __ODAWRE_l_ADAryRd="$3"
	local -n __ODAWRE_l_ODAryDst="$4"
	local -n __ODAWRE_l_DDAryDst="$5"
	local -n __ODAWRE_l_ADAryWr="$6"
	local -i l_DimNum=$7
	local -i l_NumOfElm=$8
	local -i l_WrEnd
	local -i l_AbsAdrWr
	local -i l_iDst
	local -i l_iSrc
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Verify write element range
	ODA_AdrVfyAlignRange __ODAWRE_l_DDAryDst __ODAWRE_l_ADAryWr $l_DimNum $l_NumOfElm
	l_ExitStat=$?
	if [[ l_ExitStat -eq GC_MDA_ESTAT_OK ]]; then
																# Verify read element range
		ODA_AdrVfyAlignRange __ODAWRE_l_DDArySrc __ODAWRE_l_ADAryRd $l_DimNum $l_NumOfElm
		l_ExitStat=$?
		if [[ l_ExitStat -eq GC_MDA_ESTAT_OK ]]; then
																# Get element size
			ODA_GetDimElmDataSize __ODAWRE_l_DDAryDst $l_DimNum l_WrEnd
			l_ExitStat=$?
			if [[ l_ExitStat -eq GC_MDA_ESTAT_OK ]]; then
				l_WrEnd=$((l_WrEnd * l_NumOfElm))	# Calc total write size
																# Get absolute array write address
				ODA_GetAbsAdr __ODAWRE_l_DDAryDst __ODAWRE_l_ADAryWr l_AbsAdrWr
				l_WrEnd=$(( l_WrEnd + l_AbsAdrWr ))	# Calc write end
																# Get absolute array read address
				ODA_GetAbsAdr __ODAWRE_l_DDArySrc __ODAWRE_l_ADAryRd l_iSrc
																# Write values to array
				for ((l_iDst=l_AbsAdrWr; l_iDst < l_WrEnd; l_iDst++))
				do
					__ODAWRE_l_ODAryDst[l_iDst]="${__ODAWRE_l_ODArySrc[l_iSrc]}"
					((l_iSrc++))							# Inc read index
				done
			fi
		fi
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                       Extract MDA To New MDA - MDA                          *
#*******************************************************************************
#
# Function:
#	Extracts all or part of a source MDA to a new destination MDA. The base for
#	the MDA extract is specified by an extract ADA. The dimension number and
#	number of elements to be extracted are specified by integer arguments.
#
# Input:
#	Arg1 = Source MDA variable name.
#	Arg2 = Source extract ADA variable name.
#	Arg3 = Destination MDA variable name.
#	Arg4 = Dimension number.
#	Arg5 = Number of elements to extract.
#
# Output:
#	Arg3 = New MDA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Extract ()
{
	local -n __MDAEE_l_MDArySrc="$1"
	local	-n __MDAEE_l_ADAryRd="$2"
	local -n __MDAEE_l_MDAryDst="$3"
	local	-i l_DimNumSrc=$4
	local	-i l_NumOfElm=$5
	local -a l_DDAryDst=()
	local -a l_DDArySrc
	local	-i l_DataSizeSrc
	local -i l_NumOfDimSrc
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAEE_l_MDArySrc l_DDArySrc l_NumOfDimSrc l_DataSizeSrc; then
		ODA_PadAdr l_DDArySrc __MDAEE_l_ADAryRd	# Pad source address
																# Use ODA function with info
		ODA_Extract __MDAEE_l_MDArySrc l_DDArySrc __MDAEE_l_ADAryRd __MDAEE_l_MDAryDst l_DDAryDst $l_DimNumSrc $l_NumOfElm
		l_ExitStat=$?
		if [[ l_ExitStat -eq $GC_MDA_ESTAT_OK ]]; then
																# Create new MDA
			MDA_Create __MDAEE_l_MDAryDst l_DDAryDst
			l_ExitStat=$?
		fi
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                       Extract MDA To New MDA - ODA                          *
#*******************************************************************************
#
# Function:
#	Extracts all or part of a source ODA to a new destination ODA given a source
#	DDA. The base for the ODA extract is specified by an extract ADA. The
#	dimension number and number of elements to be extracted are specified by
#	integer arguments.
#
# Input:
#	Arg1 = Source ODA variable name.
#	Arg2 = Source DDA variable name.
#	Arg3 = Source extract ADA variable name.
#	Arg4 = Destination ODA variable name.
#	Arg5 = Destination DDA variable name.
#	Arg6 = Dimension number.
#	Arg7 = Number of elements to copy.
#
# Output:
#	Arg4 = New ODA.
#	Arg5 = New DDA.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_Extract ()
{
	local -n __ODAEE_l_ODArySrc="$1"
	local -n __ODAEE_l_DDArySrc="$2"
	local	-n __ODAEE_l_ADAryRd="$3"
	local -n __ODAEE_l_ODAryDst="$4"
	local -n __ODAEE_l_DDAryDst="$5"
	local	-i l_DimNumSrc=$6
	local	-i l_NumOfElm=$7
	local -i l_SrcAdr=0
	local -i l_ArySize=0
	local -i l_iAry=0
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Verify element address and alignment
	ODA_AdrVfyAlignRange __ODAEE_l_DDArySrc __ODAEE_l_ADAryRd $l_DimNumSrc $l_NumOfElm
	l_ExitStat=$?
	if [[ $l_ExitStat -eq $GC_MDA_ESTAT_OK ]]; then
																# Get source address
		ODA_GetAbsAdr __ODAEE_l_DDArySrc __ODAEE_l_ADAryRd l_SrcAdr
																# Get dimension element size
		ODA_GetDimElmDataSize __ODAEE_l_DDArySrc $l_DimNumSrc l_ArySize
		l_ExitStat=$?
		if [[ l_ExitStat -eq GC_MDA_ESTAT_OK ]]; then
																# Calc element size
			l_ArySize=$(( l_ArySize * l_NumOfElm ))
			__ODAEE_l_ODAryDst=()						# Copy source ODA to destination
			for ((l_iAry=0; l_iAry < l_ArySize; l_iAry++))
			do
				__ODAEE_l_ODAryDst[l_iAry]="${__ODAEE_l_ODArySrc[l_SrcAdr++]}"
			done
																# Create element DDA
			ODA_DimToDDA __ODAEE_l_DDArySrc $l_DimNumSrc $l_NumOfElm __ODAEE_l_DDAryDst
			ExitStat=$?
		fi
	fi
	return $l_ExitStat
}

#*******************************************************************************
#*                   Copy MDA Structure To New MDA - MDA                       *
#*******************************************************************************
#
# Function:
#	Copies all or part of a source MDA structure to a new destination MDA and
#	initializes it with a specified value. The dimension number and number of
#	elements to be copied are specified by integer arguments.
#
# Input:
#	Arg1 = Source MDA variable name.
#	Arg2 = Destination MDA return variable name.
#	Arg3 = Dimension number.
#	Arg4 = Number of elements.
#	Arg5 = Element initialization value.
#
# Output:
#	Arg2 = Element DDA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_CopyStruc ()
{
	local -n __MDACSTR_l_MDArySrc="$1"
	local -n __MDACSTR_l_MDAryDst="$2"
	local	-i l_DimNum=$3
	local	-i l_NumOfElm=$4
	local	l_InitVal="$5"
	local -a l_DDAElm=()
	local -a l_DDAry
	local	-i l_DataSize
	local -i l_NumOfDim
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDACSTR_l_MDArySrc l_DDAry l_NumOfDim l_DataSize; then
																# Use ODA function with info
		ODA_CopyStruc l_DDAry __MDACSTR_l_MDAryDst l_DDAElm $l_DimNum $l_NumOfElm "$l_InitVal"
		l_ExitStat=$?
		if [[ l_ExitStat -eq $GC_MDA_ESTAT_OK ]]; then
			MDA_Create __MDACSTR_l_MDAryDst l_DDAElm	# Create element MDA
			l_ExitStat=$?
		fi
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                   Copy MDA Structure To New MDA - ODA                       *
#*******************************************************************************
#
# Function:
#	Copies all or part of a source ODA structure given a source ODA to a new
#	destination ODA and initializes it with a specified value. The dimension
#	number and number of elements to be copied are specified by integer
#	arguments.
#
# Input:
#	Arg1 = Source DDA variable name.
#	Arg2 = Destination ODA variable name.
#	Arg3 = Destination DDA return variable name.
#	Arg4 = Dimension number.
#	Arg5 = Number of elements.
#	Arg6 = Element initialization value.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_CopyStruc ()
{
	local -n __ODACSTR_l_DDArySrc="$1"
	local -n __ODACSTR_l_ODAryDst="$2"
	local -n __ODACSTR_l_DDAryDst="$3"
	local	-i l_DimNum=$4
	local	-i l_NumOfElm=$5
	local	l_InitVal="$6"
	local -i l_ArySize=0
	local -i l_iAry=0
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Check dimension number
	if [[ l_DimNum -lt ${#__ODACSTR_l_DDArySrc[@]} ]]; then
																# Get dimension element size
		ODA_GetDimElmDataSize __ODACSTR_l_DDArySrc $l_DimNum l_ArySize
		l_ExitStat=$?
		if [[ l_ExitStat -eq GC_MDA_ESTAT_OK ]]; then
																# Calc element size
			l_ArySize=$(( l_ArySize * l_NumOfElm ))
			__ODACSTR_l_ODAryDst=()						# Fill element with init value
			for ((l_iAry=0; l_iAry < l_ArySize; l_iAry++))
			do
				__ODACSTR_l_ODAryDst[l_iAry]="$l_InitVal"
			done
			ODA_DimToDDA __ODACSTR_l_DDArySrc $l_DimNum $l_NumOfElm __ODACSTR_l_DDAryDst
			ExitStat=$?
		fi
	else
		l_ExitStat=$GC_MDA_ESTAT_DIM_NUM				# If dimension doesn't exist
	fi
	return $l_ExitStat
}

#*******************************************************************************
#*                               Expand MDA - MDA                              *
#*******************************************************************************
#
# Function:
#	Expands an MDA dimension size or number of dimensions. The expand dimension
#	number, address, and number of elements are specified by integer arguments.
#	See the ODA_Expand function for usage details.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = Initialization value.
#	Arg3 = Expand dimension number.
#	Arg4 = Expand dimension address.
#	Arg5 = Expand number of elements.
#
# Output:
#	Arg1 = Expanded MDA.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Expand ()
{
	local -n __MDAEA_l_MDAryDst="$1"
	local l_InitVal="$2"
	local	-i l_InsDimNum=$3
	local -i l_DimInsAdr="$4"
	local	-i l_InsNumOfElm=$5
	local -a l_DDAry
	local	-i l_DataSize
	local -i l_NumOfDim
	local -a l_DBAryElm
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# If good MDA information
	if MDA_GetDesc __MDAEA_l_MDAryDst l_DDAry l_NumOfDim l_DataSize; then
		if ODA_Expand __MDAEA_l_MDAryDst l_DDAry l_NumOfDim "$l_InitVal" $l_InsDimNum $l_DimInsAdr $l_InsNumOfElm; then
			MDA_Create __MDAEA_l_MDAryDst l_DDAry	# Convert ODA to MDA
			l_ExitStat=$?									# Exit with convert status
		else
			l_ExitStat=$?									# If add error
		fi
	else														# If bad MDA
		l_ExitStat=$?
	fi
	return $l_ExitStat
}

#*******************************************************************************
#*                               Expand MDA - ODA                              *
#*******************************************************************************
#
# Function:
#	Expands an ODA/DDA dimension size or number of dimensions. The expand
#	dimension number, address, and number of elements are specified by integer
#	arguments.
#
#	To expand the number of dimensions set the Expand dimension number to one
#	larger than the current size. For example, if you want to expand a 2
#	dimensional array to 3 dimensional set the Expand dimension number to 3 and
#	the Expand dimension address to the insert address. For example if you wish
#	to insert a third dimension at the beginning of a 2 dimensional MDA set the
#	address to 0, to insert in the middle set it to 1, to insert at the end set
#	it to 2. The number of dimensions added is specified by the Expand number of
#	elements.
#
#	To expand a dimension size set the Expand dimension number to the existing
#	target dimension and the Expand dimension address to the insert address. For
#	example, if you want to expand at the beginning of dimension with a size of
#	2 set the address to 0, to insert in the middle set it to 1, to insert at
#	the end set it to 2. The expansion size is specified by the Expand number of
#	elements.
#
# Input:
#	Arg1 = ODA return variable name.
#	Arg2 = DDA return variable name.
#	Arg3 = Number of dimensions.
#	Arg4 = Initialization value.
#	Arg5 = Expand dimension number.
#	Arg6 = Expand dimension address.
#	Arg7 = Expand number of elements.
#
# Output:
#	Arg1 = Expanded ODA.
#	Arg2 = Expanded DDA.
#
# Exit Status:
#	Standard MDA return status.
#
function ODA_Expand ()
{
	local -n __ODAEA_l_ODAryDst="$1"
	local -n __ODAEA_l_DDAryDst="$2"
	local -n __ODAEA_l_NumOfDim="$3"
	local l_InitVal="$4"
	local	-i l_InsDimNum=$5
	local -i l_DimInsAdr="$6"
	local	-i l_InsNumOfElm=$7
	local -a l_DDAryDstCpy=()
	local	-i l_NumOfDimCpy=0
	local -i l_ArySizeOrig=0
	local -i l_ArySizeNew=0
	local -i l_AddAdr=0
	local -i l_ElmDataInsSize=0
	local -i l_DimDataSize=0
	local -i l_DataSizeMaxIdx=0
	local -i l_iTmp=0
	local -i l_TmpInt=0
	local -i l_iSrc=0
	local -i l_iDst=0
	local -i l_DataAddSize=0
																# Use copy of number of dims until end
	l_NumOfDimCpy=$__ODAEA_l_NumOfDim
	l_DDAryDstCpy=( ${__ODAEA_l_DDAryDst[@]} )	# Use copy of DDAryDst until end
																# Get original array size
	ODA_GetUserDataSize l_DDAryDstCpy l_ArySizeOrig
#
# Add Dimensions If Needed
# ------------------------
# If the add dimension number is greater than current we need to add dimensions
# to destination DDA with a default size of 1. The exception is for the add
# dimension if the array is empty. In that case the size is 0 because nothing
# is in that dimension yet.
#
	l_TmpInt=$((l_NumOfDimCpy - 1))			# Get last dimension number
																# If empty array and adding below last dimension
	if [[ l_ArySizeOrig -eq 0 && l_InsDimNum -lt l_TmpInt ]]; then
		return $GC_MDA_ESTAT_DIM_NUM					# Return invalid dimension error
	fi
																# If we need to add dimensions
	if [[ l_NumOfDimCpy -le l_InsDimNum ]]; then
																# If last dimension is 0
		if [[ ${l_DDAryDstCpy[l_TmpInt]} -eq 0 ]]; then
			l_DDAryDstCpy[l_TmpInt]=1					# Set it to 1
		fi
																# Process remaining dimensions
		for ((l_iTmp=l_NumOfDimCpy; l_iTmp <= l_InsDimNum; l_iTmp++))
		do														# If add dimension and array is empty
			if [[ l_iTmp -eq l_InsDimNum && $l_ArySizeOrig -eq 0  ]]; then
				l_DDAryDstCpy+=( 0 )						# New dimension size is 0
			else 												# If not add dimension or array not empty
				l_DDAryDstCpy+=( 1 )						# New dimension size is 1
			fi
		done
		l_NumOfDimCpy=$((l_InsDimNum + 1))	# Set new number of dimensions
	fi
#
# Get Current Array Parameters
# ----------------------------
																# Verfiy dimension address
	ODA_DimAdrVfy $l_InsDimNum $l_NumOfDimCpy $l_DimInsAdr ${l_DDAryDstCpy[l_InsDimNum]:--1}
	l_TmpInt=$?
	if [[ l_TmpInt -ne GC_MDA_ESTAT_OK ]]; then
		return $l_TmpInt									# Exit if error
	fi
																# Get element data size
	ODA_GetDimElmDataSize l_DDAryDstCpy $l_InsDimNum l_ElmDataInsSize
	l_TmpInt=$?
	if [[ l_TmpInt -ne GC_MDA_ESTAT_OK ]]; then
		return $l_TmpInt									# Exit if error
	fi
																# Calc absolute add address
	l_AddAdr=$(( l_DimInsAdr * l_ElmDataInsSize ))
																# Get dimension data size
	ODA_GetDimDataSize l_DDAryDstCpy $l_InsDimNum l_DimDataSize
	l_TmpInt=$?
	if [[ l_TmpInt -ne GC_MDA_ESTAT_OK ]]; then
		return $l_TmpInt									# Exit if error
	fi

	(( l_ElmDataInsSize *= l_InsNumOfElm))			# Calc final element data add size

#
# Insert Element Into Array
# -------------------------
																# Create new DDA
	(( l_DDAryDstCpy[l_InsDimNum] += l_InsNumOfElm ))
																# Get new array size
	ODA_GetUserDataSize l_DDAryDstCpy l_ArySizeNew

	l_DataSizeMaxIdx=$(( $l_DimDataSize - 1 ))	# Last index for dim data size fragment
	l_iSrc=$(( l_ArySizeOrig - 1 ))					# Init source transfer index to end of source
	l_iDst=$(( l_ArySizeNew	- 1 ))					# Init destination transfer index to end of destination
																# First transfer is add dim size - add address
	l_DataAddSize=$(( $l_DimDataSize - $l_AddAdr ))
	while [ $l_iDst -ge 0 ]								# Loop until destination full
	do
																# Move data fragment
		for ((l_iTmp=0; l_iTmp < l_DataAddSize; l_iTmp++))
		do
			__ODAEA_l_ODAryDst[l_iDst]="${__ODAEA_l_ODAryDst[l_iSrc]}"
			(( l_iSrc-- ))
			(( l_iDst-- ))
		done
																# Copy element
		l_iTmp=l_ElmDataInsSize-1
		while [[ l_iTmp -ge 0 && l_iDst -gt -1 ]]
		do
			__ODAEA_l_ODAryDst[l_iDst]="$l_InitVal"
			(( l_iDst-- ))
			(( l_iTmp-- ))
		done

		if [[ l_DataSizeMaxIdx -le l_iSrc ]]; then
			l_DataAddSize=$l_DimDataSize			# Set normal transfer size
		else
			l_DataAddSize=$(( l_iSrc + 1 ))		# Otherwise set last fragment size
		fi
	done

	l_TmpInt=${#__ODAEA_l_ODAryDst[@]}				# Get final array size
	if [[ l_TmpInt -gt l_ArySizeNew ]]; then		# If we need to unset garbage elements at end
		l_iDst=$(( l_TmpInt - 1 ))						# Get index of first unset element
		l_TmpInt=$(( l_TmpInt - l_ArySizeNew ))	# Calc number of elements to unset
																# Unset elements
		for ((l_iTmp=0; l_iTmp < l_TmpInt; l_iTmp++))
		do
			unset __ODAEA_l_ODAryDst[l_iDst]
			(( l_iDst-- ))
		done
	fi

	__ODAEA_l_NumOfDim=$l_NumOfDimCpy				# Return new number of dimensions
	__ODAEA_l_DDAryDst=( ${l_DDAryDstCpy[@]} )	# Return new DDA

	return $GC_MDA_ESTAT_OK
}

#*******************************************************************************
#*                             Contract MDA - MDA                              *
#*******************************************************************************
#
# Function:
#	Contracts an MDA dimension size or number of dimensions. The contract
#	dimension number, address, and number of elements are specified by integer
#	arguments. See the ODA_Contract function for usage details.
#
# Input:
#	Arg1 = MDA variable name.
#	Arg2 = Contract ADA variable name.
#	Arg3 = Contract dimension number.
#	Arg4 = Contract number of elements.
#	Arg5 = Contract high dimension flag.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Contract ()
{
	local -n __MDAED_l_MDArySrc="$1"
	local -i l_DimDelAdr="$2"
	local	-i l_DelDimNum=$3
	local	-i l_DelNumOfElm=$4
	local	-i l_FlgContractHi=$5
	local -a l_DDArySrc
	local	-i l_DataSizeSrc
	local -i l_NumOfDimSrc
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Get MDA information
	if MDA_GetDesc __MDAED_l_MDArySrc l_DDArySrc l_NumOfDimSrc l_DataSizeSrc; then
																# Delete MDADB
		__MDAED_l_MDArySrc=( "${__MDAED_l_MDArySrc[@]:0:l_DataSizeSrc}" )
																# Use ODA function with info
		ODA_Contract __MDAED_l_MDArySrc l_DDArySrc l_NumOfDimSrc $l_DimDelAdr $l_DelDimNum  $l_DelNumOfElm $l_FlgContractHi
		l_ExitStat=$?
		if [[ l_ExitStat -eq $GC_MDA_ESTAT_OK ]]; then
																# Create MDA
			MDA_Create __MDAED_l_MDArySrc l_DDArySrc
			l_ExitStat=$?
		fi
	else
		l_ExitStat=$?
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                             Contract MDA - MDA                              *
#*******************************************************************************
#
# Function:
#	Contracts a ODA/DDA dimension size or number of dimensions. The contract
#	dimension number, address, and number of elements are specified by integer
#	arguments.
#
#	Dimension contraction is accomplished by deleting all of a dimensions
#	elements. However only the highest dimension, or lower dimensions with a size
#	of 1, can be contracted. Furthermore there are two options for the highest
#	dimension. If the Contract high dimension flag is 0 then deleting all of its
#	elements results in an empty MDA with the lower dimension structure intact
#	and the highest dimension with a size of 0. If it's 1 then it results in an
#	empty MDA with a single zero sized X dimension. 
#
#	To contract a dimension size set the Contract dimension number to the target
#	dimension and the Contract dimension address to the contract address. For
#	example, if you want to contract at the beginning of dimension with a
#	size of 2 set the address to 0, to contract in the middle set it to 1, to
#	contract at the end set it to 2. The contract size is specified by the
#	Contract number of elements.
#
# Input:
#	Arg1 = ODA variable name.
#	Arg2 = DDA variable name.
#	Arg3 = DDA number of dimensions.
#	Arg4 = Contract address ADA variable name.
#	Arg5 = Contract dimension number.
#	Arg6 = Contract number of elements.
#	Arg7 = Contract high dimension flag.
#
# Output:
#	No parameters passed.
#
# Exit Status:
#	No status passed.
#
function ODA_Contract ()
{
	local -n __ODAED_l_MDArySrc="$1"
	local -n __ODAED_l_DDArySrc="$2"
	local -n __ODAED_l_DDAryNumOfDims="$3"
	local -i l_DimDelAdr="$4"
	local	-i l_DelDimNum=$5
	local	-i l_DelNumOfElm=$6
	local	-i l_FlgContractHi=$7
	local -i l_DelAdr=0
	local -i l_ElmDataDelSize=0
	local -i l_ArySizeOrig=0
	local -i l_ArySizeNew=0
	local -i l_DimDataSize=0
	local -i l_NewDelDimSize=0
	local	-i l_DelDimSize=0
	local -i l_TmpInt=0
	local -i l_iSrc=0
	local -i l_iDst=0
	local -i l_DataMoveSize=0
	local -i l_ExitStat=$GC_MDA_ESTAT_OK
																# Check For Argument Errors
	ODA_DimAdrVfyRange $l_DelDimNum $__ODAED_l_DDAryNumOfDims $l_DimDelAdr $(( ${__ODAED_l_DDArySrc[l_DelDimNum]:-0} - 1 )) $l_DelNumOfElm
	l_ExitStat=$?
	if [[ l_ExitStat -ne GC_MDA_ESTAT_OK ]]; then
		return $l_ExitStat								# Exit if error
	fi
																# Get current dimension size
	l_DelDimSize=${__ODAED_l_DDArySrc[l_DelDimNum]}
																# Get dimension size after delete
	l_NewDelDimSize=$(( $l_DelDimSize - l_DelNumOfElm ))
																# If deleting last element and not highest dimension
	if [[ l_NewDelDimSize -eq 0 && l_DelDimNum -ne $(( __ODAED_l_DDAryNumOfDims - 1 )) ]]; then
		if [[ l_DelDimSize -eq 1 ]]; then			# If delete dim size is 1 then contract dimensions
			iDst=$l_DelDimNum
			iSrc=$(( l_DelDimNum + 1 ))
			l_TmpInt=$(( __ODAED_l_DDAryNumOfDims - l_DelDimNum - 1 ))
echo "ODA_Contract: Set iDst = $iDst, Set iSrc = $iSrc, Move limit l_TmpInt = $l_TmpInt"
		
			for ((l_iTmp=0; l_iTmp < l_TmpInt; l_iTmp++))
			do
echo "ODA_Contract: Transferring iDst = $iDst, to iSrc = $iSrc"

				__ODAED_l_DDArySrc[iDst]=${__ODAED_l_DDArySrc[iSrc]}
				(( iDst++ ))
				(( iSrc++ ))
			done
echo "ODA_Contract: Unsetting iDst = $iDst"
			unset __ODAED_l_DDArySrc[iDst]
		else													# If delete dim size more than 1
			l_ExitStat=$GC_MDA_ESTAT_DIM_CHAIN		# Set dimension chain break error
		fi
		return $l_ExitStat
	fi
																# Get dimension element data size
	ODA_GetDimElmDataSize __ODAED_l_DDArySrc $l_DelDimNum l_ElmDataDelSize
	l_ExitStat=$?
	if [[ l_ExitStat -ne $GC_MDA_ESTAT_OK ]]; then
		return $l_ExitStat
	fi
																# Calc absolute delete address
	l_DelAdr=$(( l_DimDelAdr * l_ElmDataDelSize ))
																# Get original array size
	ODA_GetUserDataSize "${!__ODAED_l_DDArySrc}" l_ArySizeOrig
																# Calc data delete size for all delete elements
	l_ElmDataDelSize=$(( l_ElmDataDelSize * l_DelNumOfElm))
																# Get new array size
	l_ArySizeNew=$(( l_ArySizeOrig - l_ElmDataDelSize))
																# Get dimension offset
	ODA_GetDimDataSize __ODAED_l_DDArySrc $l_DelDimNum l_DimDataSize
	l_ExitStat=$?
	if [[ l_ExitStat -ne $GC_MDA_ESTAT_OK ]]; then
		return $l_ExitStat
	fi

	l_iDst=$l_DelAdr										# Init destination transfer index
	l_iSrc=$(( l_iDst + l_ElmDataDelSize ))		# Init source transfer index to end of source
																# Init data move size
	l_DataMoveSize=$(( l_DimDataSize - l_ElmDataDelSize ))
																# If beyond array size
	if [[ l_DataMoveSize -ge l_ArySizeNew ]]; then
		l_DataMoveSize=$(( l_ArySizeNew - l_DelAdr ))
	fi

	while [[ l_iSrc -lt l_ArySizeOrig ]]			# Loop until end of source
	do
																# Move data fragment
		for ((l_iTmp=0; l_iTmp < l_DataMoveSize; l_iTmp++))
		do

			__ODAED_l_MDArySrc[l_iDst]="${__ODAED_l_MDArySrc[l_iSrc]}"
			(( l_iSrc++ ))
			(( l_iDst++ ))
		done

		l_iSrc=$(( l_iSrc + l_ElmDataDelSize ))	# Calc next source transfer index
		l_TmpInt=$(( l_ArySizeOrig - l_iSrc ))		# Calc number of elements left
		if [[ l_TmpInt -lt l_DataMoveSize ]]; then
			l_DataMoveSize=$l_TmpInt
		fi
	done
																# Unset garbage elements at end
	for ((l_iTmp=(l_ArySizeOrig - 1); l_iTmp >= l_iDst; l_iTmp--))
	do
		unset __ODAED_l_MDArySrc[l_iTmp]
	done
																# If empty array and contract high dim flag set
	if [[ l_ArySizeNew -eq 0  && l_FlgContractHi -eq 1 ]]; then
		__ODAED_l_DDArySrc=(0)							# Collapse array to single empty X dimension
	else
																# Else set new array dimension size
		__ODAED_l_DDArySrc[l_DelDimNum]=$l_NewDelDimSize
	fi

	return $l_ExitStat
}

#*******************************************************************************
#*                                 Array Print                                 *
#*******************************************************************************
#
# Function:
#	Prints a multi-dimensional array.
#
# Input:
#	Arg1 = MDA variable name.
#
# Output:
#	None.
#
# Exit Status:
#	Standard MDA return status.
#
function MDA_Print ()
{
	local -n __MDAP_l_MDAry="$1"
	local -i l_DataSize=0
	local -i l_NumOfDim=0
	local -a l_DDAry=()
	local -a l_AdrAry=()
	local -a l_IncInfoAry=()
	local -a l_XColSizeAry=()
	local l_AryVal=""
	local -i l_Len=0
	local -i l_AbsAryIdx=0
	local -i l_XDimDSize=0
	local l_TmpVal=""
	local -i l_XColSize=0
	local -i l_iDim=0
	local -i l_FlgZeroCheckXY=0
	local l_LeadPad=""
	local -i l_LastDimNum=0
	local -i l_ColSepSize=4
	local -i l_YLblSize=0
	local -i l_HiDimInc=0
	local -i l_NumOfPads=0
	local -i l_FlgWrap=0
																# Get multi-dimensional array information
	MDA_GetDesc __MDAP_l_MDAry l_DDAry l_NumOfDim l_DataSize
	l_TmpVal=$?
	if [ $l_TmpVal -ne $GC_MDA_ESTAT_OK ]; then	# If fail
		return $l_TmpVal
	fi
																# Output array dimensions
	echo -e "\nMDA Print - Array Dimensions: (${l_DDAry[@]})"
	printf "            Preprocessing %'.f user elements ...\n" $l_DataSize
	if [ $l_DataSize -lt 1 ]; then					# If empty array
		echo "Array is empty."
		return $GC_MDA_ESTAT_EMPTY						# Return empty status
	fi
																# Create address array
	for ((l_iDim=0; l_iDim < l_NumOfDim; l_iDim++))
	do
		l_AdrAry[l_iDim]=0
	done

	l_LastDimNum=$(( l_NumOfDim - 1 ))				# Set last dimension number
	if [ $l_NumOfDim -gt 1 ]; then					# If 2 or more dimensions
		l_FlgZeroCheckXY=1								# Set zero check XY flag
	fi

#
# ----------------------
# Calculate Column Sizes
# ----------------------
#
	l_XDimDSize="${l_DDAry[0]}"						# Get X dimension size
																# Reset all X column sizes
	for ((l_iDim=0; l_iDim < $l_XDimDSize; l_iDim++))
	do
		l_XColSizeAry[l_iDim]=0
	done

	l_FlgWrap=0
	while [ $l_FlgWrap -eq 0  ]						# Process until end of array
	do
															
		ODA_GetAbsAdr l_DDAry l_AdrAry l_TmpVal	# Get absolute array index
		l_AryVal="${__MDAP_l_MDAry[l_TmpVal]}"		# Get value
		l_Len="${#l_AryVal}"								# Get value string length
		l_iDim=${l_AdrAry[0]}							# Get current X column index value
 																# If longest so far
		if [[ $l_Len -gt ${l_XColSizeAry[l_iDim]} ]]; then
			l_XColSizeAry[l_iDim]=$l_Len				# Set new column size
		fi
																# Inc array address
		ODA_IncInfo l_DDAry l_NumOfDim l_AdrAry l_IncInfoAry l_HiDimInc l_FlgWrap
	done

#
# ------------
# Output Array
# ------------
#
	echo -e "            Printing array ...\n"
																# Reset counter and inc info array
	for ((l_iDim=0; l_iDim < ${#l_AdrAry}; l_iDim++))
	do
		l_AdrAry[l_iDim]=0
		l_IncInfoAry[$l_iDim]=$GC_MDA_INC_RST
	done

	l_FlgWrap=0
	l_LeadPad=""
	l_HiDimInc=$l_LastDimNum							# Init high dim incremented

	if [ $l_NumOfDim -gt 1 ]; then					# If at least 2 dims
		l_YLblSize=${#l_DDAry[1]}						# Create Y label size from dims
	else
		l_YLblSize=1										# Otherwise it's just 1
	fi

	while [ $l_FlgWrap -eq 0  ]						# Output until end of array
	do
# Output Z+ Index Information
# ---------------------------
		if [ $l_HiDimInc -gt 1 ]; then				# If higher than Y dims changed
																# Output Y+ dimension labels
			for ((l_iDim=l_HiDimInc; l_iDim > 1; l_iDim--))
			do
																# Get number of pads for this dimension
				l_NumOfPads=$(( l_LastDimNum - l_iDim ))
				if [ $l_NumOfPads -gt 0 ]; then
					l_TmpVal=$(( l_NumOfPads * 4 ))
					l_LeadPad=`printf "%0.s " $(seq 1 $l_TmpVal)`
				else
					l_LeadPad=""
				fi
				echo -en "${l_LeadPad}"

				case $l_iDim in 
					2)											# Z dimension
						l_TmpVal="Z"
					;;

					3)											# W dimension
						l_TmpVal="W"
					;;

					*)											# W+ dimension
						l_TmpVal="W+$(( l_iDim - 3 ))"
					;;
				esac

				echo -e "$l_TmpVal = ${l_AdrAry[l_iDim]} --->"
			done

			(( l_NumOfPads++ ))							# Create final lead pad for XY output
			l_TmpVal=$(( l_NumOfPads * 4 ))
			l_LeadPad=`printf "%0.s " $(seq 1 $l_TmpVal)`

		fi

# Output X Index Labels
# ---------------------
		l_TmpVal=0											# Zero check lower <2 dimensions
		if [[ l_FlgZeroCheckXY -eq 0 ]]; then		# If only X
			if [[ ${l_IncInfoAry[0]} -eq $GC_MDA_INC_RST ]]; then
				l_TmpVal=1
			fi
		else													# If X and Y
			if [[ ${l_IncInfoAry[0]} -eq $GC_MDA_INC_RST && ${l_IncInfoAry[1]} -eq $GC_MDA_INC_RST ]]; then
				l_TmpVal=1
			fi
		fi

		if [ $l_TmpVal -eq 1 ]; then					# If lower <2 dims zero
			echo -en "$l_LeadPad"						# Output lead pad
			printf "%0.s " $(seq 1 $l_YLblSize)		# Output Y index column space
			echo -n "X "									# Output X row label and space for Y seperator
																# Write X index numbers
			for ((l_iDim=0; l_iDim < $l_XDimDSize; l_iDim++))
			do													# If not end of X dimension
				if  [[ l_iDim -ne $l_XDimDSize-1 ]]; then
																# Add column seperator to column size
					l_XColSize=$(( ${l_XColSizeAry[l_iDim]} + l_ColSepSize ))
				else
																# Else no column seperator for column size
					l_XColSize=${l_XColSizeAry[l_iDim]}
				fi
				printf "%-${l_XColSize}s" "$l_iDim"	# Output X index
			done
			echo ""											# Newline

			echo -en "$l_LeadPad"						# Output lead pad
			printf "%-${l_YLblSize}s" "Y"				# Output Y column label
			echo -en "  "									# Output spaces for Y index seperator 
																# Write X index underlines
			for ((l_iDim=0; l_iDim < $l_XDimDSize; l_iDim++))
			do
																# Output underline
				printf "%0.s-" $(seq 1 ${l_XColSizeAry[l_iDim]})
																# If not end of X dimension
				if  [[ l_iDim -ne $l_XDimDSize-1 ]]; then
																# Output column seperator
					printf "%0.s " $(seq 1 $l_ColSepSize)
				fi
			done
			echo ""											# Newline
		fi

# Output Y Index Label
# --------------------
		l_iDim=${l_AdrAry[0]}							# Get current X column index value
		if [ $l_iDim -eq 0 ]; then						# If first X value
			echo -en "$l_LeadPad"						# Output lead pad

			if [ $l_NumOfDim -gt 1 ]; then			# If at least 2 dims
											
				l_TmpVal=${l_AdrAry[1]}					# Get current Y index
			else
				l_TmpVal=0									# Otherwise it's just 0
			fi
			printf "%-${l_YLblSize}s" "$l_TmpVal"	# Output Y index
			echo -n "| "									# Output seperator
		fi

# Output Array Value
# ------------------
															
																# If not end of X dimension
		if  [[ l_iDim -ne $l_XDimDSize-1 ]]; then	# Add column seperator to column size
			l_XColSize=$(( ${l_XColSizeAry[l_iDim]} + l_ColSepSize ))
		else
			l_XColSize=${l_XColSizeAry[l_iDim]}		# Else no column seperator for column size
		fi
		ODA_GetAbsAdr l_DDAry l_AdrAry l_TmpVal	# Get absolute array index
																# Output value
		printf "%-${l_XColSize}s" "${__MDAP_l_MDAry[l_TmpVal]}"

# Increment Dimension Indexes
# ---------------------------
																# Inc array address
		ODA_IncInfo l_DDAry l_NumOfDim l_AdrAry l_IncInfoAry l_HiDimInc l_FlgWrap
																# If X dimension end
		if [[ ${l_IncInfoAry[0]} -eq $GC_MDA_INC_RST ]]; then
			echo ""											# Output newline
		fi

		if [ $l_FlgWrap -eq 1 ]; then					# If end of array
			echo ""											# Output space line

		elif [ $l_NumOfDim -gt 1 ]; then			# Else if at least 2 dims
																# If Y dimension end
			if [[ ${l_IncInfoAry[1]} -eq $GC_MDA_INC_RST ]]; then
				echo ""										# Output space line
			fi
		fi
	done

	return $GC_MDA_ESTAT_OK
}
