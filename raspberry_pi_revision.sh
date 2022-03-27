#!/bin/bash

function run_rpifinder()
{
	# Learn about our user's RPi hardware configuration by reading the revision number stored in '/proc/cpuinfo'
	
	# Get revision number
		#local HEXREVISION="$1" # uncomment this (and comment-out the line below this) if you want to pass revision numbers to this script instead of auto-detecting
		local HEXREVISION=$(cat /proc/cpuinfo | grep Revision | cut -d ' ' -f 2) # Get revision number from cpuinfo (revision number is in hex)
	
	# Convert revision number into a 32 bit binary string with leading zero's (name it "REVCODE")
		local BINREVISION=$(echo "obase=2; ibase=16; ${HEXREVISION^^}" | bc) # Convert revision number from hex to binary (bc needs upper-case)
		local COUNTBITS=${#BINREVISION}
		if (( "$COUNTBITS" < "32" )); then # If the revision number is not 32 bits long, add leading zero's to it - Note: $(printf "%032d\n" $BINREVISION) doesn't work with large numbers
			local ZEROSNEEDED=$((32-COUNTBITS))
			local LEADINGZEROS=$(printf "%0${ZEROSNEEDED}d\n" 0)
			local REVCODE=${LEADINGZEROS}${BINREVISION}
		elif (( "$COUNTBITS" == "32" )); then
			REVCODE=${BINREVISION}
		else
			echo "Something went wrong with calculating the Pi's revision number."
			run_giveup
		fi
	
	# Parse $REVCODE (find substrings, determine new-format vs old-format, decipher/store info in variables, print info for the user).
		# Now that REVCODE is readable in binary, create hexadecimal substrings from it.
		#       New-style revision codes: NOQuuuWuFMMMCCCCPPPPTTTTTTTTRRRR
		#         - https://www.raspberrypi.com/documentation/computers/raspberry-pi.html
		#         - https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/raspberry-pi/revision-codes.adoc
		#       If a is constant, b=${a:12:5} does substring extraction where 12 is the offset (zero-based) and 5 is the length.
		#         - https://stackoverflow.com/questions/428109/extract-substring-in-bash
		local N=${REVCODE:0:1}                                           # Overvoltage (0: Overvoltage allowed, 1: Overvoltage disallowed)
		local O=${REVCODE:1:1}                                           # OTP Program (0: OTP programming allowed, 1: OTP programming disallowed)
		local Q=${REVCODE:2:1}                                           # OTP Read (0: OTP reading allowed, 1: OTP reading disallowed)
		#local uuu=$(echo "obase=16; ibase=2; ${REVCODE:3:3}" | bc)      # Unused bits
		local W=${REVCODE:6:1}                                           # Warranty bit (0: Warranty is intact, 1: Warranty has been voided by overclocking)
		#local u=${REVCODE:7:1}                                          # Unused bit
		local F=${REVCODE:8:1}                                           # New flag (1: new-style revision, 0: old-style revision)
		local MMM=$(echo "obase=16; ibase=2; ${REVCODE:9:3}" | bc)       # Memory size (0: 256MB, 1: 512MB, 2: 1GB, 3: 2GB, 4: 4GB, 5: 8GB)
		local CCCC=$(echo "obase=16; ibase=2; ${REVCODE:12:4}" | bc)     # Manufacturer (0: Sony UK, 1: Egoman, 2: Embest, 3: Sony Japan, 4: Embest, 5: Stadium)
		local PPPP=$(echo "obase=16; ibase=2; ${REVCODE:16:4}" | bc)     # Processor (0: BCM2835, 1: BCM2836, 2: BCM2837, 3: BCM2711)
		local TTTTTTTT=$(echo "obase=16; ibase=2; ${REVCODE:20:8}" | bc) # Type (0: A, 1: B, 2: A+, 3: B+, 4: 2B, 5: Alpha (early prototype), 6: CM1, 8: 3B, 
		                                                                 #       9: Zero, A: CM3, C: Zero W, D: 3B+, E: 3A+, F: Internal use only, 10: CM3+, 
		                                                                 #       11: 4B, 12: Zero 2 W, 13: 400, 14: CM4)
		local RRRR=$(echo "obase=16; ibase=2; ${REVCODE:28:4}" | bc)     # Revision (0, 1, 2, etc.)
		
		# Zero-out our variables in case this function runs twice (this step might be redundant)
		PI_OVERVOLTAGE=""
		PI_OTPPROGRAM=""
		PI_OTPREAD=""
		PI_WARRANTY=""
		PI_RAM=""
		PI_MANUFACTURER=""
		PI_PROCESSOR=""
		PI_TYPE=""
		PI_REVISION=""
		
		if [ "$F" = "0" ]; then
			# Old-style revision codes:
			case $HEXREVISION in
				"0002")
					PI_TYPE="1B"
					PI_REVISION="1.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0003")
					PI_TYPE="1B"
					PI_REVISION="1.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0004")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0005")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Qisda"
					;;
				"0006")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0007")
					PI_TYPE="1A"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0008")
					PI_TYPE="1A"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0009")
					PI_TYPE="1A"
					PI_REVISION="2.0"
					PI_RAM="256MB"
					PI_MANUFACTURER="Qisda"
					;;
				"000d")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Egoman"
					;;
				"000e")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"000f")
					PI_TYPE="1B"
					PI_REVISION="2.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Egoman"
					;;
				"0010")
					PI_TYPE="1B+"
					PI_REVISION="1.2"
					PI_RAM="512MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0011")
					PI_TYPE="CM1"
					PI_REVISION="1.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0012")
					PI_TYPE="1A+"
					PI_REVISION="1.1"
					PI_RAM="256MB"
					PI_MANUFACTURER="Sony UK"
					;;
				"0013")
					PI_TYPE="1B+"
					PI_REVISION="1.2"
					PI_RAM="512MB"
					PI_MANUFACTURER="Embest"
					;;
				"0014")
					PI_TYPE="CM1"
					PI_REVISION="1.0"
					PI_RAM="512MB"
					PI_MANUFACTURER="Embest"
					;;
				"0015")
					PI_TYPE="1A+"
					PI_REVISION="1.1"
					PI_RAM="256MB/512MB"
					PI_MANUFACTURER="Embest"
					;;
				*)
					PI_TYPE="UNKNOWN"
					PI_REVISION="UNKNOWN"
					PI_RAM="UNKNOWN"
					PI_MANUFACTURER="UNKNOWN"
					run_giveup
					;;
			esac
			echo -e "Raspberry Pi Model ${PI_TYPE} Rev ${PI_REVISION} with ${PI_RAM} of RAM. Manufactured by ${PI_MANUFACTURER}."
			
		elif [ "$F" = "1" ]; then
			# New-style revision codes:
			case $N in
				"0")
					PI_OVERVOLTAGE="allowed"
					;;
				"1")
					PI_OVERVOLTAGE="disallowed"
					;;
				*)
					PI_OVERVOLTAGE="UNKNOWN"
					run_giveup
					;;
			esac
			
			case $O in
				"0")
					PI_OTPPROGRAM="allowed"
					;;
				"1")
					PI_OTPPROGRAM="disallowed"
					;;
				*)
					PI_OTPPROGRAM="UNKNOWN"
					run_giveup
					;;
			esac
			
			case $Q in
				"0")
					PI_OTPREAD="allowed"
					;;
				"1")
					PI_OTPREAD="disallowed"
					;;
				*)
					PI_OTPREAD="UNKNOWN"
					run_giveup
					;;
			esac
			
			case $W in
				"0")
					PI_WARRANTY="intact"
					;;
				"1")
					PI_WARRANTY="voided by overclocking"
					;;
				*)
					PI_WARRANTY="UNKNOWN"
					run_giveup
					;;
			esac
			
			case $MMM in
				"0")
					PI_RAM="256MB"
					;;
				"1")
					PI_RAM="512MB"
					;;
				"2")
					PI_RAM="1GB"
					;;
				"3")
					PI_RAM="2GB"
					;;
				"4")
					PI_RAM="4GB"
					;;
				"5")
					PI_RAM="8GB"
					;;
				*)
					PI_RAM="UNKNOWN"
					run_giveup
					;;
			esac
			
			case $CCCC in
				"0")
					PI_MANUFACTURER="Sony UK"
					;;
				"1")
					PI_MANUFACTURER="Egoman"
					;;
				"2")
					PI_MANUFACTURER="Embest"
					;;
				"3")
					PI_MANUFACTURER="Sony Japan"
					;;
				"4")
					PI_MANUFACTURER="Embest"
					;;
				"5")
					PI_MANUFACTURER="Stadium"
					;;
				*)
					PI_MANUFACTURER="UNKNOWN"
					run_giveup
					;;
			esac
			
			case $PPPP in
				"0")
					PI_PROCESSOR="BCM2835"
					;;
				"1")
					PI_PROCESSOR="BCM2836"
					;;
				"2")
					PI_PROCESSOR="BCM2837"
					;;
				"3")
					PI_PROCESSOR="BCM2711"
					;;
				*)
					PI_PROCESSOR="UNKNOWN"
					run_giveup
					;;
			esac
			
			case $TTTTTTTT in
				"0")
					PI_TYPE="1A"
					;;
				"1")
					PI_TYPE="1B"
					;;
				"2")
					PI_TYPE="1A+"
					;;
				"3")
					PI_TYPE="1B+"
					;;
				"4")
					PI_TYPE="2B"
					;;
				"5")
					PI_TYPE="Alpha (early prototype)"
					;;
				"6")
					PI_TYPE="CM1"
					;;
				"8")
					PI_TYPE="3B"
					;;
				"9")
					PI_TYPE="Zero"
					;;
				"A")
					PI_TYPE="CM3"
					;;
				"C")
					PI_TYPE="Zero W"
					;;
				"D")
					PI_TYPE="3B+"
					;;
				"E")
					PI_TYPE="3A+"
					;;
				"F")
					PI_TYPE="Internal use only"
					;;
				"10")
					PI_TYPE="CM3+"
					;;
				"11")
					PI_TYPE="4B"
					;;
				"12")
					PI_TYPE="Zero 2 W"
					;;
				"13")
					PI_TYPE="400"
					;;
				"14")
					PI_TYPE="CM4"
					;;
				*)
					PI_TYPE="UNKNOWN"
					run_giveup
					;;
			esac
			PI_REVISION="1.${RRRR}"
			
			echo -e "\nRaspberry Pi Model ${PI_TYPE} Rev ${PI_REVISION} ${PI_PROCESSOR} with ${PI_RAM} of RAM. Manufactured by ${PI_MANUFACTURER}."
			echo "(Overvoltage ${PI_OVERVOLTAGE}. OTP programming ${PI_OTPPROGRAM}. OTP reading ${PI_OTPREAD}. Warranty ${PI_WARRANTY})"
		else
			echo "ERROR: Could not read the Raspberry Pi's revision code version bit."
			run_giveup
		fi
		
	# Categorize the Pi into a series (based on the $PI_TYPE variable)
		if [ "$PI_TYPE" = "4B" ] || [ "$PI_TYPE" = "400" ] || [ "$PI_TYPE" = "CM4" ]; then
			PI_SERIES=Pi4
		elif [ "$PI_TYPE" = "3A+" ] || [  "$PI_TYPE" = "3B+" ] || [  "$PI_TYPE" = "CM3+" ]; then
			PI_SERIES=Pi3+
		elif [ "$PI_TYPE" = "Zero 2 W" ]; then
			PI_SERIES=PiZ2
		elif [ "$PI_TYPE" = "3B" ] || [  "$PI_TYPE" = "CM3" ]; then
			PI_SERIES=Pi3
		elif [ "$PI_TYPE" = "Zero" ] || [ "$PI_TYPE" = "Zero W" ]; then
			PI_SERIES=PiZ1
		elif [ "$PI_TYPE" = "2B" ]; then
			PI_SERIES=Pi2
		elif [ "$PI_TYPE" = "1A+" ] || [ "$PI_TYPE" = "1B+" ]; then
			PI_SERIES=Pi1+
		elif [ "$PI_TYPE" = "1A" ] || [ "$PI_TYPE" = "1B" ] || [ "$PI_TYPE" = "CM1" ]; then
			PI_SERIES=Pi1
		elif [ "$PI_TYPE" = "Internal use only" ] || [ "$PI_TYPE" = "Alpha (early prototype)" ]; then
			PI_SERIES=X
		else
			echo "Error: Could not identify Pi series.">&2
			run_giveup
		fi
		echo -e "\nThis Pi is part of the ${PI_SERIES} series."
}

function run_detect_arch()  # Finds what kind of processor we're running (aarch64, armv8l, armv7l, x86_64, x86, etc)
{
    KARCH=$(uname -m) # don't use 'arch' since it is not supported by Termux
    
    if [ "$KARCH" = "aarch64" ] || [ "$KARCH" = "aarch64-linux-gnu" ] || [ "$KARCH" = "arm64" ] || [ "$KARCH" = "aarch64_be" ]; then
        ARCH=ARM64
        echo -e "\nDetected an ARM processor running in 64-bit mode (detected ARM64)."
    elif [ "$KARCH" = "armv8r" ] || [  "$KARCH" = "armv8l" ] || [  "$KARCH" = "armv7l" ] || [  "$KARCH" = "armhf" ] || [  "$KARCH" = "armel" ] || [  "$KARCH" = "armv8l-linux-gnu" ] || [  "$KARCH" = "armv7l-linux-gnueabi" ] || [  "$KARCH" = "armv7l-linux-gnueabihf" ] || [  "$KARCH" = "armv7a-linux-gnueabi" ] || [  "$KARCH" = "armv7a-linux-gnueabihf" ] || [  "$KARCH" = "armv7-linux-androideabi" ] || [  "$KARCH" = "arm-linux-gnueabi" ] || [  "$KARCH" = "arm-linux-gnueabihf" ] || [  "$KARCH" = "arm-none-eabi" ] || [  "$KARCH" = "arm-none-eabihf" ]; then
        ARCH=ARM32
        echo -e "\nDetected an ARM processor running in 32-bit mode (detected ARM32)."
    elif [ "$KARCH" = "x86_64" ]; then
        ARCH=x64
        echo -e "\nDetected an x86_64 processor running in 64-bit mode (detected x64)."
    elif [ "$KARCH" = "x86" ] || [ "$KARCH" = "i386" ] || [ "$KARCH" = "i686" ]; then
        ARCH=x86
        echo -e "\nDetected an x86 (or x86_64) processor running in 32-bit mode (detected x86)."
    else
        echo "Error: Could not identify processor architecture.">&2
        run_giveup
    fi
    
    # References:
    #   https://unix.stackexchange.com/questions/136407/is-my-linux-arm-32-or-64-bit
    #   https://bgamari.github.io/posts/2019-06-12-arm-terminology.html
    #   https://superuser.com/questions/208301/linux-command-to-return-number-of-bits-32-or-64/208306#208306
    #   https://stackoverflow.com/questions/45125516/possible-values-for-uname-m

    # Testing:
    #   RPi4B 64-bit OS: aarch64 (if I remember correctly)
    #   RPi4B & RPi3B+ 32-bit: armv7l
    #   Termux 64-bit with 64-bit proot: aarch64 (if I remember correctly)
    #   Termux 64-bit with 32-bit proot: armv8l
    #   Exagear RPi3/4 (32bit modified qemu chroot): i686 (if I remember correctly)
}

function run_gather_os_info()
{
    # To my knowledge . . .
    #    Most post-2012 distros should have a standard '/etc/os-release' file for finding OS
    #    Pre-2012 distros (& small distros) may not have a canonical way of finding OS.
    #
    # Each release file has its own 'standard' vars, but five highly-conserved vars in all(?) os-release files are ...
    #    NAME="Alpine Linux"
    #    ID=alpine
    #    VERSION_ID=3.8.1
    #    PRETTY_NAME="Alpine Linux v3.8"
    #    HOME_URL="http://alpinelinux.org"
    #
    # Other known os-release file vars are listed here: https://docs.google.com/spreadsheets/d/1ixz0PfeWJ-n8eshMQN0BVoFAFnUmfI5HIMyBA0uK43o/edit#gid=0
    #
    # In general, we need to know: $ID (distro) & $VERSION_ID (distro version) into order to add Wine repo's for certain distro's/versions.
    # If $VERSION_CODENAME is available then we should probably use this for figuring out which repo to use
    #
    # We will also have to determine package manager later, which we might try to do multiple ways (whitelist based on distro/version vs runtime detection)

    # Try to find the os-release file on Linux systems
    if [ -e /etc/os-release ];       then OS_INFOFILE='/etc/os-release'     #&& echo "Found an OS info file located at ${OS_INFOFILE}"
    elif [ -e /usr/lib/os-release ]; then OS_INFOFILE='/usr/lib/os-release' #&& echo "Found an OS info file located at ${OS_INFOFILE}"
    elif [ -e /etc/*elease ];        then OS_INFOFILE='/etc/*elease'        #&& echo "Found an OS info file located at ${OS_INFOFILE}"
    # Add mac OS  https://apple.stackexchange.com/questions/255546/how-to-find-file-release-in-os-x-el-capitan-10-11-6
    # Add chrome OS
    # Add chroot Android? (uname -o  can be used to find "Android")
    else OS_INFOFILE='' && echo "No Linux OS info files could be found!">&2 && run_giveup;
    fi
    
    # Load OS-Release File vars into memory (reads vars like "NAME", "ID", "VERSION_ID", "PRETTY_NAME", and "HOME_URL")
    source "${OS_INFOFILE}"
    
    # Print out some variables from the $OS_INFOFILE we found
    echo -e "\nRunning ${ID} ${VERSION_ID} ${VERSION_CODENAME} - ${HOME_URL}"
}

function run_giveup()
{
	echo "Something went wrong. Please report errors to the github."
	exit
}

run_gather_os_info
run_detect_arch
run_rpifinder "$@"
