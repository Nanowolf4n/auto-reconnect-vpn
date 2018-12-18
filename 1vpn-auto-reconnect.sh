#!/bin/bash +x

# Source: http://www.gabsoftware.com/tips/automatically-reconnect-to-your-vpn-on-linux/
# antoniy  https://gist.github.com/antoniy
# Script forked: Wolflairovi4

# Description:
# Make the script executable "chmod +x /path/to/the/script.sh
# The script can be bound to shortcut keys with these commands:
#   /path/to/the/script.sh start # starts and monitors VPN connection
#   /path/to/the/script.sh stop  # stops the monitor and also the VPN connection

#----------------------------------------
# Config #
#----------------------------------------

# You can see those with "nmcli con" command
VPN_NAME="Change to your" 
VPN_UID="Change to your"

# Delay in secconds
DELAY=5

# File path with write permission to the executing user to store script status information
ENABLE_LOG=true

# Enable/disable ping connection check
PING_CHECK_ENABLED=true

# Check IP/Hostname #
CHECK_HOST="1.1.1.1"

# Configure DISPLAY variable for desktop notifications
DISPLAY=0.0

#----------------------------------------

 #syslog writer
 if [[ $ENABLE_LOG != false ]]; then
 	 exec 1> >(logger -s -t $(basename $0)) 2>&1
 fi
 #---
if [[ $1 == "stop" ]]; then

  nmcli connection down uuid $VPN_UID
  echo "VPN monitoring service STOPPED!"
  notify-send "VPN monitoring service STOPPED!"
  
  SCRIPT_FILE_NAME=`basename $0`
  PID=`pgrep -f $SCRIPT_FILE_NAME`
  kill $PID  
elif [[ $1 == "start" ]]; then
  while [ "true" ]
  do
    VPNCON=$(nmcli connection show | grep $VPN_NAME | cut -f1 -d " ")
    if [[ $VPNCON != $VPN_NAME ]]; then
      echo "Disconnected from $VPN_NAME, trying to reconnect..."
      (sleep 0.5 && nmcli connection up uuid $VPN_UID)
    else
       echo "Already connected to $VPN_NAME!"
    fi
    VPN_EN=$(nmcli connection show --active | grep -o $VPN_NAME)
    if [[ $VPN_NAME  != $VPN_EN ]]; then
      (nmcli connection up uuid $VPN_UID)
      echo "Current VPN connection is not active! Trying to enable."
    fi
    sleep $DELAY
    if [[ $PING_CHECK_ENABLED = true ]]; then
      PINGCON=$(ping $CHECK_HOST -c1 -q | grep -E '1 received')
      if [[ $PINGCON != *1*received* ]]; then
        echo "Ping check timeout ($CHECK_HOST), trying to reconnect..."
        (nmcli connection down uuid $VPN_UID)
        (sleep 0.5 && nmcli connection up uuid $VPN_UID)
#      else
#        echo "Ping check ($CHECK_HOST) - OK!"
      fi
    fi
  done
  echo "VPN monitoring service STARTED!"
 # notify-send "VPN monitoring service STARTED!"
else 
  echo "Unrecognised command: $0 $@"
  echo "Please use $0 [start|stop]" 
  notify-send "UNRECOGNIZED COMMAND" "VPN monitoring service could not recognise the command!"
fi