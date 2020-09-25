#!/bin/bash

#####################################################
# Title Name            : Nagios Script
# Description           : Manage Host, HostGroup, Service and other options using BashScript
# Author                : Praveen Prabhakaran
# Date                  : 25-Sep-2020
# Version               : 1.0.0
# Additional Notes      : 
#####################################################


##### Defining Variable
hosts_directory=hosts         # host folder


print_options() {
echo -e "
Choose from following Options

      1) Add a new Host
      2) Add a new HostGroup
      3) Add a new Service
      4) Add a new ServiceGroup
      5) Add a new ContactGroup
      6) Add a Host to an existing HostGroup
      7) Add a Service to exiting ServiceGroup
      8) Add contacts and contact groups
      9) time period
"
}

current_host_list() {
  # printf -- "----------------------------------------------------------------\n"
  printf -- "\n\n------------- Current List of Host and IP Address --------------\n\n"
  list_files=$(find . -type f -iname "*.cfg" -exec grep -irl "define\s\+host\s*{" {} \;)
  printf -- "----------------------------------------------------------------\n"
  printf "%-15s | %-20s | %s\n"  "   HostName" "     IP Address" "        File "
  printf -- "----------------------------------------------------------------\n"
  for file in $(ls ${list_files} )
  do 
    awk '/define[[:space:]]+host[[:space:]]*{/,/}/ \
          { if ($1~/host_name/) hostname=$2; if($1~/address/) address=$2 } 
          END { printf "%-15s | %-20s",hostname,address}' ${file}
    printf " | %s\n" "${file}"
  done
  printf -- "----------------------------------------------------------------\n"
}

add_a_host() {
  clear

  host_list=$(current_host_list)             # print current host list in the server

  echo "${host_list}"
  mkdir -p ${hosts_directory}
  echo -e "
----------------
** NOTE **
This section helps you create a host configuration file for a particular server that needs to be monitored. Two parameters needs to be provided in this section, ie \"HostName\" and \"IPAddress\".  A new nagios host file will be created under \"${hosts_directory}\" directory.  The name of the file will be \"<HostName>.cfg\". So, make sure that the \"HostName\" is unique and that there are no spaces in the name ( Example Hostname: web001 )

*** IMPORTANT ***
Current host list in displayed above for reference. When prompted for \"host name\", if you specify a hostname from the list above, the corresponding configuration file will be updated with new IP address information. Alternatively, if the hostname is a new one, a new nagios host configuration file will be created.

---------------
  "
  read -r -s -p $'Press <ENTER> to continue...'
  clear
  echo -e "${host_list}\n\n"
  
  read  -p ' Enter Host Name                : ' temp_host
  read  -p ' Enter IP address of this host  : ' temp_ip

  host=$(echo $temp_host | tr -cd "[:print:]\n" )
  ip=$(echo $temp_ip | tr -cd "[:print:]\n" )
  host_template_content="define host{
  use         generic-host            ; Name of host template to use
  host_name   ${host}
  alias       ${host} server
  address     ${ip}
}"
  

  if [ -f "${hosts_directory}/${host}.cfg" ]
  then
    echo " Configuration for ${host} alreday available in file \"${hosts_directory}/${host}.cfg\" "
    permission=Y
    read -n1 -s -p "Do you really want to edit \" ${hosts_directory}/${host}.cfg\" with new information ? (Y/N) [Default=N] :  " permission
    echo ${permission^}
    case $permission in
          y|Y) echo "${host_template_content}" > "${hosts_directory}/${host}.cfg" ;;
          n|N|*) echo "Please run the script again and choose a different \"Hostname\"" ;;
    esac 
  else
    echo "${host_template_content}" > "${hosts_directory}/${host}.cfg"
  fi
  clear
  host_list=$(current_host_list)
  echo "${host_list}"



}


##### Print Options #####
print_options

read -p 'Enter your option number: ' opt_choice

case $opt_choice in 
  1) add_a_host ;;
  2) echo -e "This section adds a new HostGroup" ;;
  3) echo -e "This section adds a new Service" ;;
  4) echo -e "This section adds a new ServiceGroup" ;;
  *) echo -e "This is other options" ;;


esac