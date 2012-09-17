#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  bash_utils.sh
#
#         USAGE:  ./bash_utils.sh
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
#       CREATED: 22/07/10 18:32:23 BST
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

# Colors
Black="$(tput setaf 0)"
BlackBG="$(tput setab 0)"
DarkGrey="$(tput bold ; tput setaf 0)"
LightGrey="$(tput setaf 7)"
LightGreyBG="$(tput setab 7)"
White="$(tput bold ; tput setaf 7)"
Red="$(tput setaf 1)"
RedBG="$(tput setab 1)"
LightRed="$(tput bold ; tput setaf 1)"
Green="$(tput setaf 2)"
GreenBG="$(tput setab 2)"
LightGreen="$(tput bold ; tput setaf 2)"
Brown="$(tput setaf 3)"
BrownBG="$(tput setab 3)"
Yellow="$(tput bold ; tput setaf 3)"
Blue="$(tput setaf 4)"
BlueBG="$(tput setab 4)"
LightBlue="$(tput bold ; tput setaf 4)"
Purple="$(tput setaf 5)"
PurpleBG="$(tput setab 5)"
Pink="$(tput bold ; tput setaf 5)"
Cyan="$(tput setaf 6)"
CyanBG="$(tput setab 6)"
LightCyan="$(tput bold ; tput setaf 6)"
NC="$(tput sgr0)" # No Color

# tputcolors
prog=${0##*/}
# Text color variables
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
lgtblu=${txtbld}$(tput setaf 4) #  lightblue
txtrst=$(tput sgr0)             # Reset
info=${Cyan}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}!${txtrst}


#===  FUNCTION  ================================================================
#          NAME:  gnu_version
#   DESCRIPTION:  tests required version aganst runing version
#    PARAMETERS:  bash or sed as version number is in position 4 ( bash 4.0 )
#       RETURNS:  none
#===============================================================================

gnu_version ()
{
#set -x
   local my_command=$1
   local my_version=$2
   declare -a my_req_version=( $( echo $my_version | awk -F'.' '{ print $1, $2 }' ) )

   if [ "${my_command}" == "bash" ] || [ "${my_command}" == "sed" ]  ; then
      declare -a my_gnu_version=( $( ${my_command} --version | awk ' /^GNU/ { print $4 }' | awk -F'.' '{ print $1, $2, $3 }' ) )

   elif [ "${my_command}" == "awk" ]  ; then
			declare -a my_gnu_version=( $( ${my_command} --version | awk ' /^GNU/ { print $3 }' | awk -F'.' '{ print $1, $2, $3 }' ) )

   elif [ "${my_command}" == "grep" ]  ; then
			declare -a my_gnu_version=( $( ${my_command} --version | awk ' /^grep/ { print $4 }' | awk -F'.' '{ print $1, $2, $3 }' ) )

   else
      declare -a my_gnu_version=( $( ${my_command} --version | awk ' /^GNU/ { print $3 }' | awk -F'.' '{ print $1, $2, $3 }' ) )
      
   fi

   rightsaidfred=$[${X_cols} - 14]
   if [ "${my_gnu_version[0]}" -ge "${my_req_version[0]}" ] && [ "${my_gnu_version[1]}" -ge "${my_req_version[1]}" ]; then
      printf "${info} GNU ${my_command} ${my_gnu_version[0]}.${my_gnu_version[1]}.${my_gnu_version[2]}"
      get_cursor
      tput cup ${row} ${rightsaidfred}
      printf "[ ${Cyan}OK${txtrst} ]\n"
   else
      printf "${warn} Found GNU ${my_command} ${my_gnu_version[0]}.${my_gnu_version[1]}.${my_gnu_version[2]}  require >= ${my_req_version[0]}.${my_req_version[1]}"
      get_cursor
      tput cup ${row} ${rightsaidfred}
      printf "[${Red}fail${txtrst}]\n"
   fi
}	# ----------  end of function bash_version  ----------


#===  FUNCTION  ================================================================
#          NAME:  grep_perl
#   DESCRIPTION:  test for grep perl support ( Perl regular expression )
#                 enables grep to use same format as sed and awk
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================

grep_perl ()
{
   local output=$( ls -l |grep -s -P "(sh|pl)$" 2>&1 ) # both stdout and stderr will be captured)
   $( echo ${output} |grep -s "not compiled" )
   status=$?
   if [ ${status} -eq 1 ] ; then
      if [ ${verbose} -eq 1 ] ; then
         printf "${info} grep -P ok\n\n"
      fi
   else
      printf "${warn} grep: does not support -P (regexp)\n"
      printf "Error: grep: Support for the -P option is not compiled into this --disable-perl-regexp binary\n"
      printf "exiting\n\n"
      exit 1
   fi
}	# ----------  end of function grep_perl  ----------

#===  FUNCTION  ================================================================
#          NAME:  macchanger_present
#   DESCRIPTION:  tests for presence of macchanger
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================

macchanger_present ()
{
   declare -a my_mac=( $( macchanger --version | awk ' /MAC/ { print }' ) )
   rightsaidfred=$[${X_cols} - 14]
   if [[ ${my_mac} ]] ; then
      printf "${info} $( macchanger --version | grep -P ^GNU )"
      get_cursor
      tput cup ${row} ${rightsaidfred}
      printf "[ ${Cyan}OK${txtrst} ]\n"
   else
      printf "${warn} GNU macchanger missing try apt-get installl macchanger"
      get_cursor
      tput cup ${row} ${rightsaidfred}
      printf "[${Red}fail${txtrst}]\n"
   fi
}	# ----------  end of function macchanger_present  ----------

#===  FUNCTION  ================================================================
#          NAME:  get_term_size
#   DESCRIPTION:  does what it says on the tin
#    PARAMETERS:  none
#       RETURNS:  Y_lines, X_cols
#===============================================================================

get_term_size ()
{
   Y_lines=$(tput lines)
   X_cols=$(tput cols)
   if [ ${verbose} -eq 1 ] ; then
      printf "xcols: ${X_cols} by ylines: ${Y_lines}\n"
   fi
}	# ----------  end of function screen_size  ----------


#===  FUNCTION  ================================================================
#          NAME:  get_cursor
#   DESCRIPTION:  get current cursor position
#    PARAMETERS:  none
#       RETURNS:  row, col
#===============================================================================


get_cursor ()
{
   exec < /dev/tty
   oldstty=$(stty -g)
   stty raw -echo min 0
   # on my system, the following line can be replaced by the line below it
   #echo -en "\033[6n" > /dev/tty
   tput u7 > /dev/tty    # when TERM=xterm (and relatives)
   IFS=';' read -r -d R -a pos
   stty $oldstty
   ## change from one-based to zero based so they work with: tput cup $row $col
   row=$((${pos[0]:2} - 1))    # strip off the esc-[
   col=$((${pos[1]} - 1))
   
}	# ----------  end of function get_cursor  ----------

get_term_size
grep_perl

if [ ${verbose} -eq 1 ] ; then
   printf "key\n   Info: ${info}\n   Warning: ${warn}\n\n"
   printf "GNU util versions on dev system\n"
   gnu_version "bash" "4.1.5"
   gnu_version "sed" "4.2.1"
   gnu_version "awk" "3.1.7"
   gnu_version "grep" "2.6.3"
   macchanger_present
fi

#
### end of script
#

