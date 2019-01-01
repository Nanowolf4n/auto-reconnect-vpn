#!/bin/bash +x

# antoniy  https://gist.github.com/antoniy
# forked: Wolflairovi4

# Description:
# Make the script executable "chmod +x /path/to/the/script.sh
# The script can be bound to shortcut keys with these commands:
#   /path/to/the/script.sh start # starts and monitors VPN connection
#   /path/to/the/script.sh stop  # stops the monitor and also the VPN connection

#----------------------------------------
# Config #
#----------------------------------------

# You can see those with "nmcli con" command
VPN_NAME="Name"
VPN_UID="UUID"

# Delay in secconds
DELAY=3

#Write logs to Syslog
ENABLE_LOG=true

# Enable/disable ping connection check
PING_CHECK_ENABLED=true

# Check IP/Hostname
CHECK_HOST="8.8.8.8"

# Configure DISPLAY variable for desktop notifications
DISPLAY=0.0

#----------------------------------------

 if [[ $ENABLE_LOG != false ]]; then
 	 exec 1> >(logger -s -t $(basename $0)) 2>&1
 fi
if [[ $1 == "stop" ]]; then
  nmcli connection down uuid $VPN_UID
  echo "VPN monitoring service STOPPED!"
  notify-send "VPN monitoring service STOPPED!"
  SCRIPT_FILE_NAME=`basename $0`
  PID=`pgrep -f $SCRIPT_FILE_NAME`
  kill $PID  
	elif [[ $1 == "start" ]]; then
	echo "VPN monitoring service STARTED!"
#	notify-send "VPN monitoring service STARTED!"
	while [ "true" ]
do
	VPN_EN=$(nmcli connection show --active | grep -o $VPN_NAME)
    if [[ $VPN_NAME  != $VPN_EN ]]; then
      echo "Current VPN connection is not active! Trying to enable..."
      (sleep 0.5 && nmcli connection up uuid $VPN_UID)
    fi
    sleep $DELAY
    if [[ $PING_CHECK_ENABLED = true ]]; then
      PINGCON=$(fping -t 800 $CHECK_HOST | grep -o 'alive')
      if [[ $PINGCON != alive ]]; then
        echo "Ping check timeout ($CHECK_HOST), trying to reconnect..."
        (nmcli connection down uuid $VPN_UID)
        (sleep 0.5 && nmcli connection up uuid $VPN_UID)
#      else
#        echo "Ping check ($CHECK_HOST) - OK!"
      fi
    fi
done;

else 
  echo "Unrecognised command: $0 $@"
  echo "Please use $0 [start|stop]" 
  notify-send "UNRECOGNIZED COMMAND" "VPN monitoring service could not recognise the command!"
fi
