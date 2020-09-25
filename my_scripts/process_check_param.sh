#! /bin/bash

#####################################################
# Title Name            : Nagios Bash Script - Process Check Remote Machine
# Description           : Script to Check if particular Process is running on remote machine
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
            This script helps to checks if the specified process is running on 
            remote machine and generate OKAY and CRITICAL status in nagios.

            -----------------------------
            |  Exit Code  |    Status   |
            -----------------------------
            |      0      |  OK         |
            |      2      |  CRITICAL   |
            -----------------------------

  SYNOPSIS:
      $0 [ OPTIONS ]

  Mandatory OPTIONS :
      - t <Target Server>     # Specify Target Server IP address (IPv4)
      - p <Process Name>      # Specify name of one Process that needs to be checked
  
  Non-Mandatory OPTIONS:
      - h                     # Help to use the script
  
  USAGE  ${BLUE}$0${NoColor} ${YELLOW}[ - t <Target Server> ] [ - p <Process Name> ]${NoColor}


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

while getopts ':t:p:h' param
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
        p)    if [ ${OPTARG:0:1} == "-"  ]
              then
                  echo -e "${RED}ERROR: \"$1\" requires an argument.${NoColor}"
                  shift
                  error_status=1
              else
                  process_name=${OPTARG}
                  shift 2 
              fi
              OPTIND=1
              required_options=$(( required_options + 1 ))
              # echo ${OPTIND}
              # echo $@
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
[[ $required_options != 2 ]] && echo -e "${RED}ERROR: One or more REQUIRED options missing${NoColor}" && usage && exit 10

# echo "Target Machine  : ${target_server}"
# echo "Process Name    : ${process_name}"

########## END of getopts ##########

########## Main Section ##########


##### Set Variables #####
remote_server_user="ubuntu"                           # Sepecifying Remote User


command_to_run="ps -ef | grep  ${process_name} | grep -qv grep"
ssh -o StrictHostKeyChecking=no ${remote_server_user}@${target_server} "$command_to_run"


########## Section to get correct EXIT CODE ##########
if [ $? -eq 0 ]
then
  echo "${process_name} OK. No action required"
  exit 0
else
  echo "${process_name} NOT OK !!! ${process_name} not running"
  exit 2
fi



