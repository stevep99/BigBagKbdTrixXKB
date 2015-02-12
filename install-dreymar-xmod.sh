#!/bin/bash

## =================================================================
## ===  INSTALL-DREYMAR-XMOD.sh for DreymaR's XKB modifications  ===
## ===         by Øystein Bech "DreymaR" Gadmar, 2015            ===
## =================================================================

HeadStr="DreymaR's Big Bag Of Tricks install script (by GadOE, 2015-01)"
DescStr=\
"Shell script to apply DreymaR's changes to the X keyboard files:\n"\
"   - AngleWide Ergonomic keyboard models for pc104/pc105 keyboards,\n"\
"   - Extend mappings as a Misc option and CapsLock as a chooser (using lv5-8),\n"\
"   - the Colemak [edition DreymaR] layout, using my own lv3-4 mappings,\n"\
"   - locale variants of Colemak[eD] with 'local' or 'unified' symbol keys,\n"\
"   - mirrored Colemak[eD] for one-handed typing,\n"\
"   - and the Tarmak(1-4) transitional (step-by-step) Colemak learning layouts.\n"\
"\n"\
"- By default, this script creates a backup of the X11 files if none exist.\n"\
"- With '-o', overwrite the system X11 files (makes the mod GUI accessible).\n"\
"- With '-s <mdl loc sym>', specify a model/layout to activate immediately.\n"\
"    (Shortstr format: -s '[4|5][n|a|w|e|f] loc [ks|us]'; 'loc'(ale) is 2-letter.\n"\
"     Some model shortstr examples: '4n' is pc104, '5e' is pc105AngleWide etc.\n"\
"     E.g.: -s '5n fr us' is normal pc105 model, French Colemak[eD]'USym'.)\n"\
"- With '-?', list further instructions and default values.\n"
FootStr="Happy xkb-hacking! ~ Øystein Bech 'DreymaR' Gadmar"
#"- With '-i <dir>', specify a directory path/name to install in.\n"\
#"- With '-g', also install GTK 2.0/3.0 config for XF86 Cut/Copy/Paste.\n"\

## NOTE: The mod directory has the form "${DModTag}<date>" with DModTag='x-mod_v<VER>_'
##		- Unless you change the DModTag, it should be in the same dir as this script
##		- It has subdirectories like 'xkb' that are to be installed (one, some or all)
## NOTE: This is the new preferred way instead of patching the system files:
##		- Backup system xkb to dbak-xkb_<DATE> (and the same for any other subdirs)
##		- Copy X11/xkb to ${InstDir}/dmod-xkb, then modify files in dmod-xkb
##		- Set up setxkb.sh to run from the modified dmod-xkb
##      - Optionally (-o) overwrite the system files instead
## NOTE: The x-mod dir holds an xkb subfolder; later, there will be a locale dir too.


##-------------- init ------------------------------------------
## NOTE: '#(-a)' means that the value can be set by a command-line argument '-a <value>'

MyDATE=`date +"%Y-%m-%d_%H-%M"`
MyNAME=`basename $0`
MyPATH=`dirname $0`
#~ XVERSION='2-5-1-3ub2'
#~ XVERSION='2-10-1-1'
XVERSION='2-12-1'
## @@@ The default X11 dir under Debian/Ubuntu/etc is /usr/share/X11  @@@
## @@@ The default X11 dir under some (older) distros is /usr/lib/X11 @@@
X11DIR='/usr/share/X11'; [ -d "${X11DIR}" ] || X11DIR='/usr/lib/X11'
ModDATE=''

DModDir=`dirname $0`	# (-d) Path to the script (and mod?) root directory
ToolDir="${DModDir}/dreymar-xtools"	# The location of tool scripts (like setxkb.sh)
DModTag="x-mod_v${XVERSION}_${ModDATE}"	# (-t) Mod dir "prefix"
DBakFix='dbak-'		# (--) Backup dir prefix
DModFix='dmod-'		# (--) Modded dir prefix
#~ InstDir="${X11DIR}"		# (-i) Path to install subfolder(s) in
InstDir="${HOME}/drey-xmod"	# (-i) Path to install subfolder(s) in
WriteSys='no'		# (-o) Overwrite the original xkb dir with the modded one
Restore='0'			# (-r) Reverse: Restore from backup # instead of installing
DoBackup='ifnone'	# (-n/b) Default backup behavior is "if no backups are found"
SubDirs='all'		# (-m) Directory/-ies inside X11 to modify (e.g., 'xkb locale', 'all')
InstGTK='no'		# (-g) Whether to install the GTK 2.0/3.0 config (if not present)
SetXMap='no'		# (-x) Whether to run the setxkb script after installing
SetXStr='5aw us us'	# (-s) Shortcut string for setxkb - 'mmm ll vv' (model layout eD-variant)

HelpStr="Usage: bash ${MyNAME} [optional args]\n"\
"Run this from the directory containing the x-mod dir\n"\
"[-o] Overwrite system X11 directory    - ${WriteSys}\n"\
"[-b] Force backup       |     location - ${X11DIR}\n"\
"[-n] Force no backup    |      default - ${DoBackup}\n"\
"[-r] <#> Restore backup - 1 is oldest  - ${Restore}\n"\
"[-m] <X11 subdir(s) to mod>            - ${SubDirs}\n"\
"[-i] <Install path>                    - ${InstDir}\n"\
"[-d] <mod dir path>                    - ${DModDir}\n"\
"[-t] <mod dir prefix tag>              - ${DModTag}\n"\
"[-g] Install GTK 2.0/3.0 edit config   - ${InstGTK}\n"\
"[-x] Run the setxkbmap script, yes/no  - ${SetXMap}\n"\
"[-s] Setxkb ShortStr 'mdl loc sym'     - ${SetXStr}\n"\
"     (See setxkb help for more info on ShortStr)\n"
#~ "( - <val> : Default settings)\n"

##-------------- functions and line parser ---------------------

MyMsg()
{
	printf "\n@@@ $1 @@@\n\n"
}

PrintHelpAndExit()
{
	MyMsg "${HeadStr}"
	printf "${DescStr}\n"
	printf "${HelpStr}"
	MyMsg "${FootStr}"
	exit $1
}

MyEcho()
{
	printf "$1\n"
	[ -z "$2" ] || printf "$1\n" >> "$2"
}

MyError()
{
	MyMsg "$MyNAME - ERROR: ${@:-'Undefined error'}"
	exit 1
}

#~ MyCD()
#~ {
	#~ OldDir=`pwd`
	#~ NewDir=${1:-`pwd`}
	#~ cd ${NewDir} || MyError "Change to '${NewDir}' failed"
	#~ MyEcho "¤ Changed dir to '${NewDir}'"
#~ }

#~ if [ "$#" == 0 ]; then PrintHelpAndExit 2; fi # No args
while getopts "obngxs:m:i:d:t:r:h?" cmdarg; do
	case $cmdarg in
		o)	WriteSys='yes'			;;
		b)	DoBackup='yes'			;;
		n)	DoBackup='no'			;;
		g)	InstGTK='yes'			;;
		x)	SetXMap='yes'			;;
		s)	SetXStr="$OPTARG"		
			SetXMap='yes'			;;
		m)	SubDirs="$OPTARG"		;;
		i)	InstDir="$OPTARG"		;;
		d)	DModDir="$OPTARG"		;;
		t)	DModTag="$OPTARG"		;;
		r)	Restore="$OPTARG"		;;
		h)		PrintHelpAndExit 0	;;
		\?)		PrintHelpAndExit 0	;;
		:)		PrintHelpAndExit 1	;;
	esac
done
#~ pos_arg=${@:$OPTIND:1} # Get the remaining (positional) arg

##-------------- main ------------------------------------------

MyMsg "$HeadStr"
#~ MyEcho "¤ Working from '`pwd`'"

##	Check for a mod dir (the latest found) and if found, get its full name
DModDir=`find "${DModDir%/}/${DModTag}"* -maxdepth 0 -type d 2>/dev/null | tail -n 1`
[ -n "${DModDir}" ] || MyError "Mod root dir not found!"
MyEcho "¤ Found mod root dir '${DModDir}'"

##	Read the mod subdirs
if [ "${SubDirs}" == "all" ]; then
	SubDirs=`find "${DModDir}/"* -maxdepth 0 -type d -exec basename '{}' \; 2>/dev/null`
	SubDirs=`echo ${SubDirs}` # A trick to make a var space separated for the following echo cmd
	[ -n "${SubDirs}" ] || MyError "No mod subdirs found!"
fi
MyEcho "¤ Subdirectories to mod: '${SubDirs}'"

##	For each subdir, backup if either DoBackup = 'yes' or DoBackup = 'ifnone' and no backup exists
BackIt=''
if [ ${DoBackup} == 'yes' ]; then
	BackIt="${SubDirs}"
elif [ ${DoBackup} == 'ifnone' ] && [ ${Restore} == '0' ]; then
	for That in ${SubDirs}; do
		MyEcho "¤ Looking for '${That}' backup in '${X11DIR}'..."
		# Test for (at least one) backup dir; if none found then proceed without errors
#		if [ -z `find "${X11DIR}/${DBakFix}${That}"* -maxdepth 0 -type d 2>/dev/null | head -n 1` ]; then
		if [ -z `find "${X11DIR}/${DBakFix}${That}"* -maxdepth 0 -type d -print -quit 2>/dev/null` ]; then
			[ -n "${BackIt}" ] && BackIt+=' '	# join with ' '; note that += is a bashism
			BackIt+="${That}"
		fi
	done
fi
[ -z "${BackIt}" ] && MyEcho "¤ Backing up: None" || MyEcho "¤ Backing up: '${BackIt}'"

## Perform the actual backup(s)
## NOTE: cp -a makes an "archive" copy, preserving all attributes and links
for That in ${BackIt}; do
	[ -d "${X11DIR}/${That}" ] || MyError "Unable to backup '${That}': Directory not found!"
	sudo cp -a "${X11DIR}/${That}" "${X11DIR}/${DBakFix}${That}_${MyDATE}" || MyError "Copy error!"
done

##	For each subfolder: Restore from backup #, overwrite X11 files or make new mod folder
for That in ${SubDirs}; do
	if [ ${Restore} != '0' ]; then	# Restore from specified backup
		## Restore from backup. Pick a backup # by parameter, 1 being oldest; use 999 or such for the last one
		BackIt=`find "${X11DIR}/${DBakFix}${That}"* -maxdepth 0 -type d 2>/dev/null | head -n ${Restore} | tail -n 1`
		[ -d "${BackIt}" ] || MyError "Unable to restore from '$(basename ${BackIt})': Not found!"
		MyEcho "¤ Restoring from backup '$(basename "${BackIt}")'"
		sudo cp -a "${BackIt}/"* "${X11DIR}/${That}" 2>/dev/null || MyError "Restore copy error!"
		XKBDir="${X11DIR}/xkb"	# Setxkbmap will default to the X11 dir, but this makes it unambigous
	elif [ ${WriteSys} == 'yes' ] && [ -d "${DModDir}/${That}" ]; then	# Overwrite system files
		MyEcho "¤ Replacing files in '${X11DIR}/${That}' with mod"
		sudo cp -a "${DModDir}/${That}/"* "${X11DIR}/${That}" 2>/dev/null || MyError "System files copy error!"
		XKBDir="${X11DIR}/xkb"
	else	## Make new mod folder (will not show up in keyboard settings GUI; use setxkbmap instead)
		DoSudo=''; mkdir -p "${InstDir}" 2>/dev/null && [ -w "${InstDir}" ] || DoSudo='sudo'
		MyDir="${InstDir%/}/${DModFix}${That}"
		#~ MyDir="$(dirname "${MyDir}")/${DModFix}$(basename "${MyDir}")"	# Insert prefix in path/name
		MyEcho "¤ Installing mod files in '${MyDir}'"
		${DoSudo} mkdir -p "${MyDir}" || MyError "Can't make '${MyDir}'!"
		${DoSudo} cp -a "${X11DIR}/${That}/"* "${MyDir}" 2>/dev/null || MyError "Local files copy error!"
		${DoSudo} cp -a "${DModDir}/${That}/"* "${MyDir}" 2>/dev/null || MyError "Local files copy error!"
		XKBDir="${InstDir%/}/${DModFix}xkb"	# Prepare for setxkbmap
	fi
done

##	If selected, call the DreymaR GTK bindings install script
## The DreymaR gtk edit install script sets GTK Cut/Copy/Paste key config (if not already present)
if [ ${InstGTK} == 'yes' ]; then
	"${ToolDir}/gtk_edit_install.sh" || MyError "gtk_edit_install.sh failed!"
fi

#~ ##	Call the DreymaR setxkbmap script unless 'q' is pressed, to activate the new (default) layout
#~ That=''	#; [ ${InstGTK} == 'yes' ] && That=" and GTK edit config"
#~ MyMsg "Press any key to set the new xkb map${That}, or 'q' to quit"
#~ read -p '$>' -n 1 keypress
#~ if [ "${keypress}" == 'q' ]; then
##	If selected, call the DreymaR setxkbmap script to activate the new (default) layout
if [ "${SetXMap}" != 'yes' ]; then
	MyEcho; MyMsg "XKBmap activation skipped"
else
	#~ "${ToolDir}/setxkb.sh" -p $(dirname "${XKBDir}") -d $(basename "${XKBDir}") || MyError "setxkb.sh failed!"
	"./setxkb.sh" -d "${XKBDir}" -s "${SetXStr}" || MyError "setxkb.sh failed!"
fi

MyMsg "${MyNAME} finished!"
exit 0

##-------------- misc ------------------------------------------

#~ MyError "Debug - run halted!"	# debug
#~ echo "$1 $2 $3 $4 $5"; exit 0	# debug