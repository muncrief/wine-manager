#!/bin/bash

#*******************************************************************************
#*                                                                             *
#*                                                                             *
#*                              Standard Script Main                           *
#*                                                                             *
#*                                                                             *
#*******************************************************************************
#
# Version: 1.1
#

DbgPrint "Entered script."

#*******************************************************************************
#*                                    Traps                                    *
#*******************************************************************************
#
trap "TrapSIGHUP" SIGHUP			# SIGHUP clean up trap
trap "TrapSIGINT" SIGINT			# SIGINT clean up trap
trap "TrapSIGTERM" SIGTERM			# SIGTERM clean up trap
trap "TrapSIGKILL" SIGKILL			# SIGKILL clean up trap
