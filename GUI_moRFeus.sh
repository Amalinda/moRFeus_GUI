#!/bin/bash

# GUI for moRFeus (Outernet) tool with GQRX support.
# for moRFeus device v1.6 - LamaBleu 04/2018
#
#
# INSTALLATION
# ========================
#
#
#    git clone https://github.com/LamaBleu/moRFeus_GUI
#    cd moRFeus_GUI
#    chmod +x *.sh
#    sudo ./GUI_moRFeus.sh
#
# At first launch the script will ask you which version (32 or 64 bits) to download
# from Outernet website archives.
# If missing, packages 'yad' 'bc' and 'socat' are also installed.
#
# GUI will not launch if moRFeus device is not connected !
#
#
# Credits goes to Outernet and Alex OZ9AEC to give us so nice tools. Thanks !



#  Path to moRFeus directory (to morfeus_tool and this script).
####### Adapt to real path if not working.
#  Replacing $HOME by full name of directory may help

export morf_tool_path=$HOME/moRFeus_GUI


if [ ! -f $morf_tool_path/morfeus_tool ]; then
    echo 
    echo
    printf "\n\n\n"
    echo "#############################################"
    echo
    echo "Directory :" $morf_tool_path
    echo "Outernet morfeus_tool not found ! "
    echo
    echo "#############################################"
    echo
    printf "\n\n\n"
    echo "Trying to download from Outernet website"
    echo
    printf "\n\n\n"
    read -p "Choose OS Type 32 or 64 bits [32]: " OS
    OS=${OS:-32}
    echo
    echo
    echo "Going to download for $OS bits platform"
    if [[ $OS -eq 32 ]] ||  [[ $OS -eq 64 ]];
      then
        wget -O $morf_tool_path/morfeus_tool https://archive.outernet.is/morfeus_tool_v1.6/morfeus_tool_linux_x$OS
	userdir=$(ls -l $HOME/moRFeus_GUI/GUI_moRFeus.sh | awk '{print $3}')
	echo
	echo "Modify morfeus_tool ownership to $userdir"
	chown $userdir:$userdir $HOME/moRFeus_GUI/morfeus_tool
      else
       echo 
       echo "Huuuhhhh , NO SORRY ! 32 ou 64 only ! (or manual download : https://archive.outernet.is/morfeus_tool_v1.6/ )"
    fi
    printf "\n\n\n" 
    printf "\n\n\n"
    echo
    echo
    echo "Just in case we will install NOW yad bc socat packages "
    echo "(sudo apt-get install yad bc socat)"
    echo
    printf "\n\n\n"
    apt-get install -y socat bc yad
fi

chmod +x $morf_tool_path/morfeus_tool
chmod +x $morf_tool_path/*.sh


####### GQRX settings - GRQX_ENABLE= to avoid 'connection refused' messages
export GQRX_ENABLE=1
export GQRX_IP=127.0.0.1
export GQRX_PORT=7356


export stepper_step_int=0
export morf_tool
export GQRX_STEP="No"


function on_click () {
yad --about 
}
export -f on_click

function generator () {
$morf_tool_path/morfeus_tool Generator
}
export -f generator

function close_exit(){

    kill -USR1 $YAD_PID
}
export -f close_exit


# sent to GQRX VFO

function gqrx_vfo_send () {
if [[ $GQRX_ENABLE -eq 1 ]];
   then
#echo "gqrx_vfo_send : F "$freq_morf_a
echo "F "$freq_morf_a > /dev/tcp/$GQRX_IP/$GQRX_PORT
setgenerator
fi
}

export -f gqrx_vfo_send

# send to GQRX LNB_LO

function gqrx_lnb_send () {
if [[ $GQRX_ENABLE -eq 1 ]];
   then
#echo "gqrx_lnb_send : LNB_LO "$freq_morf_a
echo "LNB_LO "$freq_morf_a > /dev/tcp/$GQRX_IP/$GQRX_PORT
setmixer
fi
export GQRX_LNB
export freq_morf_a

}

export -f gqrx_lnb_send

function gqrx_lnb_reset () {
if [[ $GQRX_ENABLE -eq 1 ]];
   then
echo "LNB_LO 0 " > /dev/tcp/$GQRX_IP/$GQRX_PORT
fi
GQRX_LNB=0
export GQRX_LNB
close_exit
}

export -f gqrx_lnb_reset




function setfreq () {
freq_morf=${status_freq::-4}
freq_morf_a="${freq_morf/$'.'/}"

INPUTTEXT=`yad  --center --width=270 --title="set Frequency" --form --text="  Now : $freq_morf kHz" --field="Number:NUM" $freq_morf_a'\!85e6..5.4e9\!1000\!0 2>/dev/null'`  
INPUTTEXT1=${INPUTTEXT%,*}

$morf_tool_path/morfeus_tool setFrequency $INPUTTEXT1



export freq_morf_a
#export INPUTTEXT1
close_exit
}
export -f setfreq




function gqrx_get () {
if [[ $GQRX_ENABLE -eq 1 ]];
   then
     GQRX_FREQ=$(echo 'f ' | socat stdio tcp:$GQRX_IP:$GQRX_PORT,shut-none 2>/dev/null) 
     GQRX_LNB=$(echo 'LNB_LO ' | socat stdio tcp:$GQRX_IP:$GQRX_PORT,shut-none 2>/dev/null)
     #echo "GQRX VFO: $GQRX_FREQ   LNB LO: $GQRX_LNB"
   else 
      echo "GQRX disabled"
fi
export GQRX_FREQ
export GQRX_LNB

}
export -f gqrx_get


function setcurrent () {

INPUTTEXT=`yad --center --width=250 --title="set Power" --form --field="Power:CB" $status_current'!0!1!2!3!4!5!6!7' 2>/dev/null`  
INPUTTEXT1=${INPUTTEXT%,3*}
#echo "setCurrent : "$INPUTTEXT1"  , "
status_current = INPUTTEXT1
$morf_tool_path/morfeus_tool setCurrent $INPUTTEXT1

export status_current
close_exit

}
export -f setcurrent

function setmixer () {

$morf_tool_path/morfeus_tool setCurrent 0
$morf_tool_path/morfeus_tool Mixer 

close_exit

}
export -f setmixer

function setgenerator () {

$morf_tool_path/morfeus_tool Generator 

close_exit
}
export -f setgenerator



function mainmenu () {

######### get status
#export morf_tool
status_mode=$($morf_tool_path/morfeus_tool getFunction)
status_current=$($morf_tool_path/morfeus_tool getCurrent)
status_freq=$($morf_tool_path/morfeus_tool getFrequency)
#freq_morf=${status_freq::-4}
freq_morf_a="${freq_morf/$'.'/}"
export status_freq
export status_current
export freq_morf_a

gqrx_get

####### main GUI window



data="$(yad --center --title="Outernet moRFeus v1.6" --text-align=center --text=" moRFeus control \n by LamaBleu 04/2018 \n" \
--form --field=Freq:RO "$status_freq" --field="Mode:RO" "$status_mode" --field="Power:RO"  "$status_current"  \
--field=:LBL "" --form --field="Set Frequency:FBTN" "bash -c setfreq" \
--field="set Generator mode:FBTN" "bash -c setgenerator" \
--field="set Mixer mode:FBTN" "bash -c setmixer"  \
--field="Set Power:FBTN" "bash -c setcurrent" --field=:LBL "" \
--field='GQRX control':RO "  IP: $GQRX_IP Port: $GQRX_PORT"  \
--field='GQRX Freq':RO "VFO: $GQRX_FREQ    LNB LO: $GQRX_LNB " \
--field="Morfeus/Gen. + Freq --> GQRX (VFO):FBTN" "bash -c gqrx_vfo_send" \
--field="Morfeus/Mixer + Freq --> GQRX (LNB LO):FBTN" "bash -c gqrx_lnb_send" \
--field="Reset GQRX LNB LO to 0:FBTN" "bash -c gqrx_lnb_reset" "" "" "" "" "" "" "" "" "" ""  \
--button="Step generator:3"  --button="Refresh:0" --button="Quit:1" 2>/dev/null)"  


#echo " gqrx_enable : "$GQRX_ENABLE
ret=$?

### for debug
#echo $ret
#export ret
#echo $data
#if [[ $ret -eq 0 ]]; then
#	GQRX_LNB=0
#	echo ""
#fi



############# step generator


if [[ $ret -eq 3 ]]; then

# we need to switch to generator mode, and minimal power.
$morf_tool_path/morfeus_tool Generator
$morf_tool_path/morfeus_tool setCurrent 1

#echo "Stepper init Fstart: "$stepper_start_int " Fend: " $stepper_stop_int " Step Hz:  "$stepper_step_int " Hope-time : "$stepper_hop_dec \
#"Power : "$status_current "  GQRX : "$GQRX_STEP

#setting variables in advance i know why ;)
stepper_step_int=10000
stepper_start_int=$freq_morf_a
stepper_step=10000
stepper_start_in=$(echo "$freq_morf_a + 0.000000" | bc)
stepper_stop_in=$(echo "$freq_morf_a + 0.000000" | bc)
stepper_step_in=10000
stepper_hop=5.00000
stepper_hop1=5
stepper="No"
stepper_hop_dec=5.00000
stepper_step="10000"
stepper_start=$(echo "$freq_morf_a + 0.000000" | bc)
stepper_stop=$(echo "$freq_morf_a + 0.000000" | bc)
stepper_stop_int=$freq_morf_a
#$morf_tool_path/morfeus_tool setCurrent 1
############

stepper="$(yad  --center --width=320 --title="start Frequency" --form --text="  Now : $freq_morf kHz" \
--field="Start_freq:NUM" $freq_morf_a'\!85e6..5.4e9\!100000\!0' \
--field="Stop_freq:NUM" $freq_morf_a'\!85e6..5.4e9\!100000\!0' \
--field="Step Hz:NUM" $stepper_step_int'\!0..1e9\!10000\!0' \
--field="Hop (s.):NUM" '5.\!0.5..3600\!0.5\!1' \
--field="Power:CB" $status_current'\!0!1!2!3!4!5!6!7' \
--field="Send Freq to GQRX:CB" $GQRX_STEP'\!No!VFO!LNB_LO'  "" "" "" "" "" "" ) "



#ret_step=$?
#echo "ret_step "$ret_step
#export ret_step

stepper_start=$(echo $(echo $(echo "$stepper" | cut -d\| -f 1)))
stepper_stop=$(echo $(echo $(echo "$stepper" | cut -d\| -f 2)))
stepper_step=$(echo $(echo $(echo "$stepper" | cut -d\| -f 3)))
stepper_hop=$(echo $(echo $(echo "$stepper" | cut -d\| -f 4)))
stepper_current=$(echo $(echo $(echo "$stepper" | cut -d\| -f 5)))
GQRX_STEP=$(echo $(echo $(echo "$stepper" | cut -d\| -f 6)))

stepper_start="${stepper_start//,/$'.'}"
stepper_stop="${stepper_stop//,/$'.'}"
stepper_step_dec="${stepper_step//,/$'.'}"
stepper_hop_dec="${stepper_hop//,/$'.'}"
stepper_hop="${stepper_hop_dec::-5}"
#echo "stepper_hop1 ${stepper_hop1//,/$'.'}"
#echo "Stepper:" $stepper_hop1 "--"   $stepper_hop_dec "--" $stepper_hop
#stepper_start_in=$(($stepper_start))
#stepper_stop_in=$(($stepper_stop))
#stepper_step_in=$(($stepper_step))

stepper_start_int="${stepper_start::-7}"
stepper_stop_int="${stepper_stop::-7}"
stepper_step_int="${stepper_step::-7}"
#echo $stepper_start ${stepper_start::-7}

i=$((stepper_start_int))
end=$(($stepper_stop_int))
band=$(((end-i)/stepper_step_int))
band=${band#-}

#test if f_start > f_end, then launch decremental stepper
# and swap f_tart f_end variables

echo "Fstart: "$i " Fend: " $end " Step Hz: "$stepper_step_int "Hop-time: "$stepper_hop \
"Jumps: "$band "  Power : "$stepper_current "  GQRX : "$GQRX_STEP

# we need to switch to generator mode, and minimal power.
$morf_tool_path/morfeus_tool Generator
$morf_tool_path/morfeus_tool setCurrent $stepper_current


if [[ $GQRX_ENABLE -eq 1 ]];
   then
	if [[ $GQRX_STEP = "VFO" ]]; then
		#scanning start : setting GQRX LNB_LO to 0, to ensure display on correct VFO freq.
		echo "LNB_LO 0 " > /dev/tcp/$GQRX_IP/$GQRX_PORT
	fi
fi
k=0




if [[ "$stepper_start_int" > "$stepper_stop_int" ]] ; then
	echo "*** Decremental steps !"	
	stepper_step_int=-${stepper_step_int}
	#swap f_end <->f_start	
	#end=$((stepper_start_int))
	#i=$(($stepper_stop_int))
	
	else

	echo "*** Incremental steps !"
	i=$((stepper_start_int))
	end=$(($stepper_stop_int))

fi


band=$((band+1))

i=$((stepper_start_int))
	end=$(($stepper_stop_int))


while [ $k -ne $band ]; do

$morf_tool_path/morfeus_tool setFrequency $i
if [[ $GQRX_ENABLE -eq 1 ]];
   then
   if [[ $GQRX_STEP = "LNB_LO" ]]; then
      #send to LNB_LO
      #echo "GQRX LNB_LO:  " $i
      echo "LNB_LO "$i > /dev/tcp/$GQRX_IP/$GQRX_PORT
   fi

   if [[ $GQRX_STEP = "VFO" ]]; then
      #send to VFO
      #echo "GQRX VFO:  " $i
      echo "F "$i > /dev/tcp/$GQRX_IP/$GQRX_PORT
   fi  
fi
k=$((k+1))

echo "Freq: "$i" - GQRX: "$GQRX_STEP" - Jump "$k"/"$band

i=$(($i+$stepper_step_int))
#echo $i
sleep $stepper_hop

done
echo "Stepper end.    "
sleep 0.5


fi
#mainmenu
}



# Establish run order
main() {
#!/bin/bash
while :
do
#echo $ret

mainmenu
if [[ $ret -eq 1 ]];
   then
	echo "Normal exit"	
	break       	   #Abandon the loop. (quit button)
   fi
if [[ $ret -eq 127 ]];
   then
	echo "err 127 "
	break       	   #Abandon the loop. (error)
	fi
if [[ $ret -eq 252 ]];
   then
	echo "User cancel"
	break       	   #Abandon the loop. (close mainwindow)
   fi

done 
 
}

export -f mainmenu
main



