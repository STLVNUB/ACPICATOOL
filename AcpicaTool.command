#!/bin/bash
#set -x
verS="1.0"
function echob() {
echo "`tput bold`$1`tput sgr0`"
}

STARTH=`date "+%H"`
if [ $STARTH -ge 04 -a $STARTH -le 12 ]; then
    hours="Morning  "
elif [ $STARTH -ge 12 -a $STARTH -le 17 ]; then
     hours="Afternoon"
elif [ $STARTH -ge 18 -a $STARTH -le 21 ]; then
	hours="Evening  "
else
	hours="Night    "	
fi
iaslMeUp="No"
update="No"
theDate=`date +%Y%m%d`
WorkDir=$(cd -P -- $(dirname -- "$0") && pwd -P)
[ ! "${WorkDir}"/Tools ] && mkdir "${WorkDir}"/Tools
acpicaDir="${WorkDir}"/acpica
workSpaceFree=`df -m "${WorkDir}" | awk '{print $4}'`
workSpace="${workSpaceFree:10:20}"
workSpaceNeeded="522"
workSpaceMin="104"
theProg=`basename "$0"`
#what system
theSystem=`uname -r`
theSystem="${theSystem:0:2}"
case "${theSystem}" in
    [0-8]) sysmess="unsupported" ;;
    9) rootSystem="Leopard" ;;
    10) rootSystem="Snow Leopard" ;;
    11) rootSystem="Lion" ;;
    12)	rootSystem="Mountain Lion" ;;
    [13-20]) sysmess="Unknown" ;;
esac
if [ ! -d "${acpicaDir}" ] && [ "$workSpace" -lt "$workSpaceNeeded" ]; then
	echob "error!!! Not enough free space"
	echob "Need at least $workSpaceNeeded bytes free"
	echob "Only have $workSpace bytes"
	echob "move $theProg"
	echob "to different Folder"
	exit 1
elif [ "$workSpace" -lt "$workSpaceMin" ]; then
	echob "Getting low on free space"
fi
workSpaceAvail="$workSpace"
iaslMeResDir="${WorkDir}"/iaslME.app/Contents/Resources # Now we place 'New' iasl into Folder here

function getSource() # gets ACPICA github source
{
if [ ! -d "${acpicaDir}" ]; then # clone into acpica folder
	echob "Cloning ACPICA Source Code"
	echob "From: git://github.com/acpica/acpica.git"
	echob "To:   ${WorkDir}/acpica"
	git clone git://github.com/acpica/acpica.git
	return_val=$?
	if [ $return_val == 0 ]; then
		echob "Cloned -SUCCESSFULLY-"
	else
		echob "Clone -FAILED- so we EXIT!!!"
		exit 1
	fi
else	# acpica folder is made so do git pull
	echob "Checking Local ACPICA Repository"
	cd ./acpica
	gitMess=`git pull git://github.com/acpica/acpica.git 2>/dev/null`
	if [ "$gitMess" == "Already up-to-date." ]; then
		echob "ACPICA is up to date"
		if [ "$updateForce" == "No" ]; then
			update="No" # no need to update
		else
			echob "Force building" # used force switch
		fi
		return
	else
		update="Yes" # update
		if [ -f "${iaslMeResDir}"/iasl ]; then
			echob "Will Auto-Update iaslMe/iasl ${ASLBits} Bit, Dated: ${ASLDate}"
		elif [ -d "${iaslMeResDir}" ]; then
			echob "Will Install New iaslMe/iasl"
		else			
			echob "Will Make New ACPICA Tools"
		fi		
	fi
fi
sleep 2
cd ..
}

function compileIt() # compiles iasl acpiexec acpisrc acpixtract 
{
isPatched=$(cat "${WorkDir}"/acpica/source/os_specific/service_layers/osunixxf.c | grep 'termios.h')
echo "Checking source/os_specific/service_layers/osunixxf.c"
if [ "${isPatched:16:1}" == "s" ]; then
	echo "Ok, isPatched, continuing"
else
	echo "Need to patch"
	echo "Change #include <termio.h>"
	echo "TO"
	echo "#include <termios.h>"
	open -e -W "${WorkDir}"/acpica/source/os_specific/service_layers/osunixxf.c
fi
if [ ! -d "${WorkDir}"/Tools ] || [ ! -d "${WorkDir}"/Log ]; then
	echob "Make Tools and/or Log Folder"
	mkdir "${WorkDir}"/Tools "${WorkDir}"/Log 
fi	
echob "Compiling on $theDate"
cd "${WorkDir}"/acpica/generate/unix/
make clean
wait
make HOST=_APPLE # well that's all I needed to do
return_val=$?
if [ $return_val == 0 ]; then
	echob "Compiled -SUCCESSFULLY-"
else
	echob "Compile -FAILED- so we EXIT!!!"
	make clean
	exit 1
fi
wait
rm -rf "${WorkDir}"/Tools/*
PROGS='acpibin acpidump acpiexec acpihelp acpinames acpisrc acpixtract iasl'
for theProgs in $PROGS ; do
	echob "copy $theProgs to tools folder"
	cp  "${WorkDir}"/acpica/generate/unix/$theProgs/obj/$theProgs "${WorkDir}"/Tools/
done	
wait

cd ..
}
if	[ "$1" == "force" ]; then
	updateForce="Yes"
else
	updateForce="No"
fi	
echob "********************************************"
echob "*             Good $hours               *"         
echob "*              Welcome  To                 *"
echob "*        ACPICA Compile TOOL $verS           *"
echob "*        This script by STLVNUB            *"
echob "********************************************";echo
echob "running $theProg on '$rootSystem' ;)";echo
echob "Work Folder: ${WorkDir}"
echob "Available  : ${workSpaceAvail} MB";echo
cd "${WorkDir}"
if [ ! -f /usr/bin/gcc ]; then
	echob "ERROR:"
	echob "      Xcode command line Tools from Apple"
	echob "      NOT FOUND!!!"
	echob "      $theProg needs it";echo
	echob "      Going To Apple Developer Site"
	echob "      Download & Install XCode command line tools, then re-run"
	open "http://www.google.com.au/url?sa=t&rct=j&q=xcode%20command%20line%20tools&source=web&cd=2&ved=0CCkQFjAB&url=http%3A%2F%2Fdeveloper.apple.com%2Fxcode%2F&ei=RVNBUM7OGNGViQe2soCoDQ&usg=AFQjCNHQA6GfwnaQsSz6TRPjvUEhcQ-ysw"
	wait
	echob "Good $hours"
	tput bel
	exit 1
fi	
if [ -d "${iaslMeResDir}" ] || [ "$update" == "Yes" ] || [ "$iaslMeUp" == "Yes" ] ; then
	if [ -f "${WorkDir}"/Tools/iasl ]; then
		ASLVersion=`"${iaslMeResDir}"/iasl | grep "ASL Optimizing Compiler"`
		ASLVersion="${ASLVersion:32:11}"
		ASLDate="${ASLVersion:0:8}"
		ASLVersionB=`"${WorkDir}"/Tools/iasl | grep "ASL Optimizing Compiler"`
		ASLVersionB="${ASLVersionB:32:11}"
		ASLDateB="${ASLVersionB:0:8}"
		if [ "${ASLDateB}" == "${ASLDate}" ] && [ "$updateForce" == "No" ]; then
			echob "iaslMe iasl Version the 'SAME'"
			echob "${ASLDate}"
			echob "Not Compiling/Updating"
			echob "run '$0 force' to update"
			exit
		else
			
			echob "Auto Compile iasl Version ${ASLDateB}"
			echob "and copy to iaslMe"
			iaslMeUp="Yes"
		fi		
	fi	
elif [ ! -d "${iaslMeResDir}" ]; then 	
	echob "Place iaslMe app in same folder"
	echob "to Auto-Update to latest iasl"
fi
sleep 3		
getSource
wait

if  [ "$update" == "Yes" ] || [ "$iaslMeUp" == "Yes" ] || [ ! -f "${WorkDir}"/Tools/iasl ]; then
	echob "Compile"
	compileIt
	if [ -d "${iaslMeResDir}" ]; then
		echob "Update iaslMe"
		cp -R "${WorkDir}"/Tools/iasl "${iaslMeResDir}"/iasl
	fi	
fi	
echob "All done…, opening Tools Folder"
open "${WorkDir}"/Tools
exit 0