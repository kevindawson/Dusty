#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  ipaddr.sh
#
#         USAGE:  ./ipaddr.sh
#
#   DESCRIPTION:
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: kevin dawson (kpd), kevin@bowtie.org
#       COMPANY: KPD Consultancy Ltd.
#       VERSION:  0.0.1
#       CREATED: 01/07/10 19:47:20 BST
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

#-------------------------------------------------------------------------------
#  Global variables deffernitions
#-------------------------------------------------------------------------------
verbose='0'

#===  FUNCTION  ================================================================
#          NAME:  show_help
#   DESCRIPTION:  none
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================

function show_help ()
{
   
   if [[ ${1} ]] ; then
      printf "${1} You should look at this\n"
   fi
   
   printf "A little bit of help\n"
   printf "\nipaddr.sh [options]\n\n"
   printf "\toption -h display help\n"
   printf "\toption -v verbose, try this for finding errors\n"
   printf "\toption -f output 'filename'\n"
   
}	# ----------  end of function show_help  ----------


#-------------------------------------------------------------------------------
#  GetOps
#-------------------------------------------------------------------------------
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "h?vf:" opt; do
   case "$opt" in
      h) show_help "h"; exit 0;;
      v) verbose=1;;
      f) output_file=$OPTARG;;
      ?) show_help "Opps!"; exit 0;;
   esac
done
shift $((OPTIND-1))
#if [ "$1" = -- ]; then shift; fi
if [ ${verbose} -eq 1 ] ; then
   printf "verbose=${verbose}, output_file='${output_file}', Leftovers: $@\n"
fi

#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
prog=${0##*/}
prog=${prog%.*}

filename=$(basename $0)
extension=${filename##*.}
filename=${filename%.*}

#-------------------------------------------------------------------------------
#  Global variables deffernitions
#-------------------------------------------------------------------------------
output_file=''
my_TEMP_FILE='/tmp/ipaddr'
my_bash_utils='bash_utils.sh'

# the joy of Tilde expansions
##eval echo "${my_text_colour}" # ~ >> $HOME >> /home/fbloggs
eval source ${my_bash_utils}

declare -A assoc
declare -a iface
pattern1="^(eth\d+|lo|wlan\d+|mon\d+|sit\d+)"
pattern2="^(.*inet\d?)"


#===  FUNCTION  ================================================================
#          NAME:  report
#   DESCRIPTION:
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================

function report ()
{
   local elements=${#iface[@]}
   local index=$((${elements} - 1))
   local i
   local output
   printf "\n"
   for ((i = 0; i <= ${index}; i++)); do
      
      if [[ ${iface[i]} != *:* ]] ; then
         
         output=$(ping -Lc1 ${assoc[iface[$i]inet]} 2>&1) # both stdout and stderr will be captured)
         status=$?
         #echo -e " ping status ${status}"
         
         if [ ${status} -eq 0 ] ; then
            if [ ${verbose} -eq 1 ] ; then
               printf "${Green}${iface[i]}${NC} \tMac Addr: $(macchanger -s ${iface[$i]} |sed 's/Current MAC: //')\n\n"
               
            else
               printf "${Green}${iface[i]}${NC} \tMac Addr: ${assoc[iface[$i]mac]}\n"
               
            fi
            #           printf "${Green}${iface[i]}${NC} \tMac Addr: ${assoc[iface[$i]mac]}\n"
            # printf "${Green}${iface[i]}${NC} \t$(macchanger -s ${iface[$i]})\n"
            printf "IP Addr: ${Green}${assoc[iface[$i]inet]}${NC}\tName: ${Green}${assoc[iface[$i]name]}${NC}\n"
            printf "   Bcast: ${assoc[iface[$i]Bcast]}"
            printf "   Mask: ${assoc[iface[$i]Mask]}\n"
         else
            if [ ${verbose} -eq 1 ] ; then
               printf "${Red}${iface[i]}${NC} \tMac Addr: $(macchanger -s ${iface[$i]} |sed 's/Current MAC: //')\n\n"
               
            else
               printf "${Red}${iface[i]}${NC} \tMac Addr: ${assoc[iface[$i]mac]}\n"
               
            fi
         fi
         
         
      else
         printf "\t${Cyan}${iface[i]}${NC}"	# \tMac Addr: ${assoc[iface[$i]mac]}"
         printf "   IP Addr: ${Cyan}${assoc[iface[$i]inet]}${NC}\tName: ${Cyan}${assoc[iface[$i]name]}${NC}\n"
         if [ ${verbose} -eq 1 ] ; then
            printf "\tBcast: ${assoc[iface[$i]Bcast]}"
            printf "\tMask: ${assoc[iface[$i]Mask]}\n"
         fi
      fi
      
   done
   printf "\n"
}	# ----------  end of function report  ----------


#===  FUNCTION  ================================================================
#          NAME:  collect
#   DESCRIPTION:
#    PARAMETERS:
#       RETURNS:
#===============================================================================

function collect ()
{
   newline=$'\n'
   OIFS=$IFS
   IFS=$newline
   # add define array thingie
   declare -a files=($( /sbin/ifconfig -a ))
   IFS=$OIFS
   
   for i in "${files[@]}"
   do
      my_fred=$i
      my_device=$( echo $i |grep -P ${pattern1} |awk '{print $1}' )
      my_mac=$( echo $i |grep -P ${pattern1} |awk '{print $5}' )
      
      if [[ ${my_device} ]] ; then
         my_elements=${#iface[@]}
         iface[${my_elements}]=${my_device}
         assoc[iface[${my_elements}]mac]=${my_mac}
      fi
      
      my_inet=$( echo $i |grep -s -P ${pattern2} |sed 's/addr://' | awk '/inet\W/ { print $2 }' )
      if [[ ${my_inet} ]] ; then
         assoc[iface[${my_elements}]inet]=${my_inet}
         assoc[iface[${my_elements}]name]=$( dig +short +search +ndots=2 -x ${my_inet} )
      fi
      
      my_bcast=$( echo $i |grep -s -P ${pattern2} |sed 's/Bcast://' | awk '/inet\W/ { print $3 }' )
      if [[ ${my_bcast} ]] ; then
         output=$( echo ${my_bcast} |grep -s 'Mask' )
         #    echo -e "$output"
         ## [[ "$gender" == f* ]]
         ##    if ( ${output} ) ; then
         if [[ ${output} != Mask* ]] ; then
            assoc[iface[${my_elements}]Bcast]=${my_bcast}
         fi
      fi
      
      my_mask=$( echo $i |grep -s -P ${pattern2} |sed 's/Mask://' | awk '/inet\W/ { print $4 }' )
      if [[ ${my_mask} ]] ; then
         assoc[iface[${my_elements}]Mask]=${my_mask}
      fi
   done
   
}       # ----------  end of function collect  ----------


collect
report

# end unload functions: good house keeping ;)
unset show_help
unset report
unset collect
printf "\t\t${Cyan}So Long & Thanks for all the Fish${warn}${NC}\n\n"
exit 0
#
### end of script
#
