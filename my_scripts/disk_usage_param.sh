#! /bin/bash

#####################################################
# Title Name            : Nagios Bash Script - Disk Check Remote Machine
# Description           : Nagios Script to Check Disk Usage on remote machine
# Author                : Praveen Prabhakaran
# Date                  : 23-Sep-2020
# Version               : 1.0.0
# Additional Notes      : 
#####################################################



##### Color and Font Customization #####

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NoColor='\033[0m'

set_blink='\033[5m'
reset_blink='\033[25m'



########## Function Defining Usage ##########
usage() {
echo -e "

  SCRIPT: 
      ${0#./*} 
            This script helps to checks Disk Usage of a particular mount point
            on a remote machine and generate following exit code for 
            OKAY, WARNING and CRITICAL limits set.

            -----------------------------
            |  Exit Code  |    Status   |
            -----------------------------
            |      0      |  OK         |
            |      1      |  WARNING    |
            |      2      |  CRITICAL   |
            -----------------------------

  SYNOPSIS:
      $0 [ OPTIONS ]

  Mandatory OPTIONS :
      - t <Target Server>     # Specify Target Server IP address (IPv4)
      - m <Mount Point>       # Mount point on remote server that needs checking
      - w <Warning Limit>     # To set Warning Limit for the script
      - c <Critical Limit>    # To set Critical Limit for the script
  
  Non-Mandatory OPTIONS:
      - h                     # Help to use the script
  
  USAGE  ${BLUE}$0${NoColor} ${YELLOW}[ - t <Target Server> ] [ -m <Mount Point> ] [ - w <Warning Limit> ] [ - c <Critical Limit> ]${NoColor}


"
}


########## Function to validate target IP address for IPv4 Address ##########
valid_ip() {
  
    local ip=$*
    local valid=yes

    ### IPv4 address pattern matching ###
    echo $ip | grep -qE '^([0-9]{1,3}[.]){3}[0-9]{1,3}$' 
    if [ $? -ne 0 ]
    then
        valid="Not a valid IPv4 address - Incorrect Format"
        exit 10
    else 
      local IFS=.
      ip=($ip)
      for octact in ${ip[@]}
      do
          if [ ${octact} -le 0 ] || [ ${octact} -gt 255 ]
          then
            valid="Not a valid IPv4 address - Out of Range"
            break
          fi
      done
     fi 
    echo $valid

}

########## Using getopts to define OPTIONS to be used in the script ##########
required_options=0 

while getopts ':t:m:w:c:h' param
do
    case $param in
        t)    if [ ${OPTARG:0:1} == "-"  ]
              then
                  echo -e "${RED}ERROR: \"${1}\" requires an argument.${NoColor}"
                  shift
                  error_status=1
              else
                  target_server=${OPTARG}
                  check_valid=$(valid_ip $target_server)
                  if [ "${check_valid}" != 'yes' ]
                  then
                    echo ${check_valid}
                    error_status=1
                  fi
                  shift 2
              fi
              OPTIND=1
              required_options=$(( required_options + 1 ))
              # echo ${OPTIND}
              # echo $@
              ;;
        m)    if [ ${OPTARG:0:1} == "-"  ]
              then
                  echo -e "${RED}ERROR: \"$1\" requires an argument.${NoColor}"
                  shift
                  error_status=1
              else
                  mount_point=${OPTARG}
                  shift 2
              fi
              OPTIND=1
              required_options=$(( required_options + 1 ))
              # echo ${@}
              ;;
        w)    if [ ${OPTARG:0:1} == "-"  ]
              then
                  echo -e "${RED}ERROR: \"$1\" requires an argument.${NoColor}"
                  shift
                  error_status=1
              else
                  warning_limit=${OPTARG}
                  shift 2
              fi
              OPTIND=1
              required_options=$(( required_options + 1 ))
              # echo ${@}
              ;;
        c)    if [ ${OPTARG:0:1} == "-"  ]
              then
                  echo -e "${RED}ERROR: \"${1}\" requires an argument.${NoColor}"
                  shift
                  error_status=1
              else
                  critical_limit=${OPTARG}
                  shift 2
              fi
              OPTIND=1
              required_options=$(( required_options + 1 ))
              ;;
        h)    usage
              exit 10
              ;;
        \?)   echo -e "${RED}ERROR: Invalid Option \"-$OPTARG\" entered${NoColor}"
              error_status=1
              ;;
        :)    echo -e "${RED}ERROR: \"-${OPTARG}\" requires an argument.${NoColor}"
              error_status=1
              ;;
    esac

done

[[ $error_status ]] && usage && exit 10
[[ $required_options != 4 ]] && echo -e "${RED}ERROR: One or more REQUIRED options missing${NoColor}" && usage && exit 10

# echo "Target Machine  : ${target_server}"
# echo "Target Machine  : ${mount_point}"
# echo "Warning Limit   : ${warning_limit}"
# echo "Critical Limit  : ${critical_limit}"


########## END of getopts ##########




########## Main Section ##########
##### Set Variables #####
remote_server_user="ubuntu"                           # Sepecifying Remote User

command_to_run="df -hP ${mount_point} | awk '{ print \$5}' | grep -v "^Use" | sed -e 's/%//g'"
available_space=$(ssh -o StrictHostKeyChecking=no ${remote_server_user}@${target_server} " ${command_to_run} ")




########## Section to get correct EXIT CODE ##########
if [ $( echo "$available_space < ${warning_limit}" | bc )  -eq 1 ]
then
  echo "Disk OK. Percentage of space used for ${mount_point} disk is $available_space %"
  exit 0
else
  if  [ $( echo "$available_space >= ${warning_limit}" | bc ) -eq 1 ] && \
      [ $( echo "$available_space < ${critical_limit}"  | bc ) -eq 1 ]
  then
    echo "Disk is in Warning State !!! Percentage of space used for ${mount_point} disk is $available_space %"
    exit 1
  else
    if [ $( echo "$available_space >= ${critical_limit} " | bc ) -eq 1 ]
    then
      echo "Disk is in Critical State !!! Percentage of space used for ${mount_point} disk is $available_space %"
      exit 2
    fi
  fi
fi