#!/bin/bash
#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                         Multidimensional Array Variables                    *
#*                                                                             *
#*                                                                             *
#*******************************************************************************

# ~~~~~~~~~~~
# Exit Status
# ~~~~~~~~~~~
declare -r GC_MDA_ESTAT_OK=0							# No error
declare -r GC_MDA_ESTAT_NOT_MDA=1					# Not a multidimensional array
declare -r GC_MDA_ESTAT_NO_DIMS=2					# No dimensions
declare -r GC_MDA_ESTAT_DIM_SIZE=3					# Invalid dimension size
declare -r GC_MDA_ESTAT_DIM_NUM=4					# Invalid dimension number
declare -r GC_MDA_ESTAT_DATA_SIZE=5					# Wrong user data size
declare -r GC_MDA_ESTAT_EMPTY=6						# Empty array
declare -r GC_MDA_ESTAT_ADR_ALIGN=7					# Address is out of alignment error
declare -r GC_MDA_ESTAT_ADR_BOUNDS=8				# Address is out of bounds
declare -r GC_MDA_ESTAT_ADR_BOUNDS_NEG=9			# Address is negative 
declare -r GC_MDA_ESTAT_ADR_BOUNDS_LOW=10			# Low address is out of bounds
declare -r GC_MDA_ESTAT_ADR_BOUNDS_HI=11			# High address is out of bounds
declare -r GC_MDA_ESTAT_ADR_BOUNDS_HIZERO=12		# High address is out of bounds
declare -r GC_MDA_ESTAT_ELM_BOUNDS=13				# Element address is out of bounds
declare -r GC_MDA_ESTAT_ELM_BOUNDS_NEG=14			# Element address is negative 
declare -r GC_MDA_ESTAT_ELM_BOUNDS_LOW=15			# Low element address is out of bounds
declare -r GC_MDA_ESTAT_ELM_BOUNDS_HI=16			# High element address is out of bounds
declare -r GC_MDA_ESTAT_DIM_CHAIN=17				# Dimension chain break
declare -r GC_MDA_ESTAT_TOTAL=18						# Total number of exit code values

# Exit Status Message Array
# ~~~~~~~~~~~~~~~~~~~
#
declare -a GC_MDA_ESTAT_MSG_ARY						# Constant Array

GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_OK]="Exit okay"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_NOT_MDA]="Not a multidimensional array"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_NO_DIMS]="No dimensions"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_DIM_SIZE]="Invalid dimension size"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_DIM_NUM]="Invalid dimension number"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_DATA_SIZE]="Wrong user data size"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_EMPTY]="Array is empty"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ADR_ALIGN]="Address is out of alignment"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ADR_BOUNDS]="Address is out of bounds"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ADR_BOUNDS_NEG]="Address is negative"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ADR_BOUNDS_LOW]="Low address is out of bounds"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ADR_BOUNDS_HI]="High address is out of bounds"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ADR_BOUNDS_HIZERO]="Upper address is not 0"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ELM_BOUNDS]="Element address is out of bounds"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ELM_BOUNDS_NEG]="Element address is negative"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ELM_BOUNDS_LOW]="Low element address is out of bounds"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_ELM_BOUNDS_HI]="High element address is out of bounds"
GC_MDA_ESTAT_MSG_ARY[$GC_MDA_ESTAT_DIM_CHAIN]="Dimension chain break"

# ~~~~~~~~~~~~~~~~~~~~
# Miscellaneous Values
# ~~~~~~~~~~~~~~~~~~~~
declare -r GC_MDA_ID=92317547							# Multidimensional Array ID

# ~~~~~~~~~~~~
# Status Codes
# ~~~~~~~~~~~~
declare -r GC_MDA_INC_NONE=0							# No increment
declare -r GC_MDA_INC=1									# Increment
declare -r GC_MDA_INC_RST=2							# Increment reset

declare -r GC_MDA_DEC_NONE=0							# No decrement
declare -r GC_MDA_DEC=1									# Decrement
declare -r GC_MDA_DEC_RST=2							# Decrement reset

# ~~~~~~~~~~~~~~~~~~~~~~~~
# Descripter Block Indexes
# ~~~~~~~~~~~~~~~~~~~~~~~~
# Note: These are negative indexes from the end of array.
#
declare -r GC_MDA_DBI_ID=0								# Multidimensional Array ID
declare -r GC_MDA_DBI_UDSIZE=1						# User data size index
declare -r GC_MDA_DBI_NDIMS=2							# Number of dimensions index
declare -r GC_MDA_DBI_DIMSTR=3						# Dimension string 
declare -r GC_MDA_DB_SIZE=4							# Descripter block size






