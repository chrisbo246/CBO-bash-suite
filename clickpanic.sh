#!/bin/bash

script_short_description='Helpers'
script_version='0.0.1'

#    echo '$BASH_SUBSHELL:'$BASH_SUBSHELL
#    echo '$SHLVL:'$SHLVL
#[[ "$(declare -Ff '__menu')" ]]  >&2&& return
#echo $(ps -e -o cmd | grep --color clickpanic)
#pgrep -f "/bin/\w*sh $BASH_SOURCE" | grep -vq $$  >&2&& return
#[[ $(pgrep -f "/bin/\w*sh $BASH_SOURCE") ]] && return
#echo "LOAD HELPERS"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__main_menu()
{

  while true; do
    escaped_prefix=$(escape_string --sed "${file_prefix}")
    options=$(find "$(dirname $0)" -type f -regex "${file_prefix}.*\.sh" | sed -r 's/^'"$escaped_prefix"'(.*).*\.sh$/\1/' | sort 2>/dev/null)
    
    __menu -t 'Helpers' $(printf ' -o %s' $options) --back --exit
    
    filename="${file_prefix}${VALUE}.sh"
    if [ -e "$filename" ]; then
      include_once "$filename"
      "__${VALUE}_menu"
    fi
  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__install()
{  
    
  # Install completion script  
  local filename=${config_path}bash_completion.d/$(basename "${BASH_SOURCE%.*}")
  sudo sh -c 'cat > '"$filename" <<EOF
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_clickpanic_complete()
{
    local cur prev opts
    COMPREPLY=()
    cur="\${COMP_WORDS[COMP_CWORD]}"
    prev="\${COMP_WORDS[COMP_CWORD-1]}"
    opts=\$(grep -Po '^\h*(function\h+)?[a-zA-Z0-9_-]+\h*\(\h*\)\h*(\{|$|#)' "\$1" | sed 's/function[ \t]+//; s/[ \t(){#]//g' | grep -Pv '^_+' | sort)

    if [[ \${cur} == * && \${COMP_CWORD} -eq 1 ]] ; then
        COMPREPLY=( \$(compgen -W "\${opts}" -- \${cur}) )
        return 0
    fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for filename in \$(find $(dirname "$BASH_SOURCE") -maxdepth 1 -type f -name "$(basename ${BASH_SOURCE%.*})*.sh"); do
  basename=\$(basename "\$filename")
  eval '_'"\${basename%.*}"'() { _clickpanic_complete "'"\$filename"'"; };'
  eval 'complete -F _'"\${basename%.*}"' '"\$basename"
done
EOF

  local filename="${HOME}/.bashrc"
  if [[ $BASH == '/bin/bash' && -z $(grep '\. /etc/bash_completion' "$filename") ]]; then
    sudo cat >> "$filename" <<EOF
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
EOF
  fi

  sudo chmod u+x "$filename"
  . "$filename"
  #exec bash
  
  #local filename=~/.bashrc
  local filename=~/.bash_aliases
  if [[ -n "$aliases" ]]; then
    while read alias; do
      eval "$alias"
      [[ ! $(grep "$alias" "$filename") ]] && echo "$alias" >> "$filename"
    done < <(echo -e "$aliases")
  fi
  
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
available_functions()
{
  local list=()
  for filename in $(find $(dirname "$BASH_SOURCE") -maxdepth 1 -type f -name "$(basename ${BASH_SOURCE%.*})*.sh"); do
    for funct in $(grep -Po '^\h*(function\h+)?[a-zA-Z0-9_-]+\h*\(\h*\)\h*(\{|$|#)' "$filename" | sed 's/function[ \t]+//; s/[ \t(){#]//g' | grep -Pv '^_+' | sort); do
      list+=( "$funct;$filename" )
    done
  done
  printf -- "%s${IFS}" "${list[@]}" | sort
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__uninstall()
{
  # Remove completion script
  local filename=${config_path}bash_completion.d/$(basename "${BASH_SOURCE%.*}")
  [[ -f "$filename" ]] && rm "$filename"
  
  # Remove aliases
  # local filename=~/.bashrc
  local filename=~/.bash_aliases
  if [[ -n "$aliases" ]]; then
    while read string; do
      eval "un${string} >/dev/null 2>/dev/null"
      sed -r '/^[ \t]*'"$(escape_string --sed $string)"'=/d' "$filename"
    done < <(echo -e "$aliases" | grep -Po '^\h*alias\h+[^=]*')
  fi
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__menu()
{
  #[[ ! $menu_titles ]] && menu_titles=()
  local menu_options values
  local menu_prompt='Enter a number'
  local title='Menu '$((${#menu_titles[@]}+1))
  local back_level=2
  (( menu_level++ ))

  read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Select menu

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-t|--title string] [-o|--option string]... [-p|--prompt string] [--back [integer]] [--exit]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

DESCRIPTION
    Return $REPLY (the number) and $VALUE (the option text).

OPTIONS
    -t, --title
        Menu title.
    -o, --option
        The list of menu options.
    -p, --prompt
        A optionnal prompt text.
    --all
        Add an option to return all values.
    --back
        Add an option to go back to previous menu: You can provide an optional back level.
    --exit
        Add an option to exit all loops to reach the end of the script.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "t:o:p:h" -l "title:,options:prompt:,all,back::,exit,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -t|--title) shift; title=${1:-"$title"}; shift;;
      -o|--options) shift; values+=("$1"); menu_options+=("$1"); shift;;
      -p|--prompt) shift; menu_prompt="${1:-$menu_prompt}"; shift;;
      --back)
        shift
        if [[ $menu_level > 1 ]]; then
          menu_options+=('< BACK>')          
          local back_reply=${#menu_options[@]}          
        fi
        back_level=${1:-$back_level}
        shift
        ;;
      --exit) shift; menu_options+=('< EXIT >'); local exit_reply=${#menu_options[@]};;
      --all) shift; menu_options+=('< ALL >'); local all_reply=${#menu_options[@]};;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit $EX_OK;;
      --) shift; break;;
    esac
  done

  echo
  menu_titles+=("$title")
  local delimiter=' > '; string=$(printf "%s$delimiter" "${menu_titles[@]}"); echo ${string%$delimiter}

  PS3="$menu_prompt [1-$((${#menu_options[@]}+2))]:"
  select VALUE in "${menu_options[@]}"; do
    case $REPLY in
    ( $((( $REPLY >= 1 && $REPLY <= ${#menu_options[@]} )) && echo $REPLY) ) break;;
    ( ${back_reply:-back} )
      unset menu_titles[${#menu_titles[@]}-1] menu_titles[${#menu_titles[@]}-1]      
      unset VALUE
      (( menu_level-- ))      
      break $back_level
      ;;
    ( ${all_reply:-all} ) VALUE=$values;;
    ( ${exit_reply:-exit} ) exit $EX_DATAERR;;
    ( * ) echo "Invalid answer. Try another one."; continue;;
    esac
  done
  #( $(( ${#menu_options[@]}+${#more_options[@]}-1 )) ) unset menu_titles[${#menu_titles[@]}-1]; unset menu_titles[${#menu_titles[@]}-1]; $VALUE=''; break 2;;
  #( $(( ${#menu_options[@]}+${#more_options[@]})) ) exit $EX_DATAERR;;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__package_cp()
{
  local options

    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Cross platform package managment

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-f|--force] { install | uninstall package... }
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

OPTIONS
    -f, --force
        Try to resolve conflicts.
    -p, --purge

    -q, --quiet

    -qq

    -u, --show-upgraded

    -y, --yes
        Ask yes for all questions.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  # Supported package managers
  # The first available will be used so you can reorder the list to change priority.
  # Cross-platform managers should be at end.
  # http://en.wikipedia.org/wiki/List_of_software_package_management_systems
  # RPM http://pwet.fr/man/linux/administration_systeme/rpm
  local installers=(apt-get yum rpm dpkg) # pkg(ips) aptitude pacman
  local installer=$(echo -e "$(which ${installers[@]})" | head -n1 | grep -o '[^/]*$')

  local ARGS=$(getopt -o "fpqyh" -l "force,force-yes,purge,quiet,reinstall,show-upgraded,yes,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit $EX_OK;;
      --) shift; break;;
      * ) options="${options} $1"
    esac
  done

  # The first argument should be the task
  [ -z "$1" ] && echo "${IFS}${help}${IFS}"  >&2 && exit $EX_DATAERR
  local task="$1"
  shift
  
  case $task in
  clean )
    case $installer in
    apt-get ) sudo apt-get $options clean;;
    #aptitude ) sudo aptitude $options clean;;
    dpkg ) sudo dpkg $options --clear-selections --set-selections;;
    #rpm ) ;;
    yum ) sudo yum $options clean;;
    esac
    ;;
  configure )
    for package in "$@"; do
      case $installer in
      apt-get ) sudo apt-get $options configure $package;;
      #aptitude ) ;;
      dpkg ) sudo dpkg $options --configure $package;;
      #rpm ) ;;
      yum ) sudo yum $options configure $package;;
      esac
    done
    ;;
  install)
    # Make sure that sudo is installed
    if [[ ! $(which sudo) ]]; then
      #local cmd="adduser $USER sudo; su $USER"
      local user=$USER
      su root
      case $installer in
        apt-get ) apt-get install sudo;;
        aptitude ) aptitude install sudo;;
        dpkg ) dpkg --install sudo;;
        rpm ) rpm --install sudo+;;
        yum ) yum install sudo;;
        #apt-get ) su -l -c "apt-get install sudo; $cmd";;
        #aptitude ) su -l -c "aptitude install sudo; $cmd";;
        #dpkg ) su -l -c "dpkg --install sudo; $cmd";;
        #rpm ) su -l -c " --install sudo+; $cmd";;
        #yum ) su -l -c "yum install sudo; $cmd";;
      esac
      adduser $user sudo;
      su $user
    fi
      
    for package in "$@"; do
      case $installer in
      apt-get ) sudo apt-get $options install $package;;
      aptitude ) sudo aptitude $options install $package;;
      dpkg ) sudo dpkg $options --install $package;;
      rpm ) sudo rpm $options --install ${package}+;;
      yum ) sudo yum $options install $package;;
      esac
    done
    ;;
  list_installed)
    for package in "$@"; do
      case $installer in
      #apt-get ) ;;
      aptitude ) aptitude search -F '%p' '~i';;
      dpkg ) dpkg --get-selections
        #test=$(dpkg-query --show --showformat=${Status}"${IFS}" $package | grep 'install ok installed')
      ;;
      #rpm ) rpm -q --queryformat '%{NOM}';;
      yum ) yum list installed;;
      esac
    done
    ;;
  is_installed)
    for package in "$@"; do
      case $installer in
      #apt-get ) ';;
      aptitude ) aptitude search -F '%p' '~i' | grep -P '^'$package'(\s+|^)';;
      dpkg ) dpkg --get-selections | grep -P '^'$package'\t+install$';;
      rpm ) rpm --print-package-info=$package;;
      yum ) yum list installed $package;;
      esac
    done
    ;;
  purge )
    for package in "$@"; do
      case $installer in
      apt-get ) sudo apt-get $options --purge remove $package;;
      aptitude ) sudo aptitude $options purge $package;;
      dpkg ) sudo dpkg $options --purge $package;;
      #yum ) sudo yum $options --purge remove $package;;
      esac
    done
    ;;
  reinstall )
    for package in "$@"; do
      case $installer in
      apt-get ) sudo apt-get $options --reinstall install $package;;
      aptitude ) sudo aptitude reinstall $package;;
      #dpkg ) sudo dpkg $options --reinstall $package
      #rpm ) ;;
      #yum ) sudo yum $options --reinstall install $package;;
      esac
    done
    ;;
  remove)
    for package in "$@"; do
      case $installer in
      apt-get ) sudo apt-get $options remove $package;;
      aptitude ) sudo aptitude $options remove $package;;
      dpkg ) sudo dpkg $options --remove $package;;
      rpm ) sudo rpm $options --uninstall ${package}+;;
      yum ) sudo yum $options remove $package;;
      esac
    done
    ;;
  update )
    case $installer in
    apt-get ) apt-get $options update;;
    aptitude ) aptitude $options update;;
    dpkg ) dpkg $options update;;
    rpm ) rpm $options --rebuild;;
    yum ) yum $options update;;
    esac
    ;;
  upgrade )
    for package in "$@"; do
      case $installer in
      apt-get ) sudo apt-get $options upgrade;;
      #aptitude ) sudo aptitude $options update;;
      #dpkg ) sudo dpkg $options update;;
      rpm ) sudo rpm $options -U $package;;
      #yum ) sudo yum $options update;;
      esac
      [ -z "$package" ] && break
    done
    ;;    
  esac
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____edit_configuration()
{
  while true;  do
    menu /
    -t 'Edit configuration'
    -o 'Network interfaces' \
    -o 'Hosts' \
    -o 'Hostname' \
    -o 'Portfix' \
    -o 'MySQL' \
    -o 'Apache available modules' \
    -o 'Mime types' \
    -o 'Aliases' \
    -o 'Pure-FTPd' \
    -o 'Pure-FTPd TLS' \
    -o 'Mount table' \
    -o 'AW stats' \
    -o 'Failban jail' \
    -o 'Fail2ban Pure-FTPd custom filter' \
    -o 'Fail2ban dovecote custom filter' \
    -o 'Squirrelmail' \
    -o 'Postfix' \
    -o 'Cron task' \
    --back --exit

    case $REPLY in
      1 ) sudo editor ${config_path}network/interfaces; ${service_path}networking reload;;
      2 ) sudo editor ${config_path}hosts;;
      3 ) sudo editor ${config_path}hostname; ${service_path}hostname.sh reload;;
      4 ) sudo editor ${config_path}postfix/master.cf; ${service_path}postfix reload;;
      5 ) sudo editor ${config_path}mysql/my.cnf; ${service_path}mysql reload;;
      6 ) sudo editor ${config_path}apache2/mods-available/suphp.conf; ${service_path}apache2 reload;;
      7 ) sudo editor ${config_path}mime.types;;
      8 ) sudo editor ${config_path}aliases;;
      9 ) sudo editor ${config_path}default/pure-ftpd-common; ${service_path}pure-ftpd-mysql reload;;
      10 ) sudo editor ${config_path}pure-ftpd/conf/TLS; ${service_path}pure-ftpd-mysql reload;;
      11 ) sudo editor ${config_path}fstab; mount -o remount /; mount -a;;
      12 ) sudo editor ${config_path}cron.d/awstats; a2ensite awstats;;
      13 ) sudo editor ${config_path}fail2ban/jail.local; ${service_path}fail2ban reload;;
      14 ) sudo editor ${config_path}fail2ban/filter.d/pureftpd.conf; ${service_path}fail2ban reload;;
      15 ) sudo editor ${config_path}fail2ban/filter.d/dovecot-pop3imap.conf; ${service_path}fail2ban reload;;
      16 ) sudo editor ${config_path}apache2/conf.d/squirrelmail.conf; ${service_path}apache2 reload;;
      17 ) sudo editor ${config_path}postfix/main.cf; ${service_path}postfix reload;;
      17 ) sudo crontab -e;;
      #${service_path}mailman
      #${service_path}amavis
    esac

    [[ $REPLY -ge 1 && $REPLY -le ${#options[@]} ]] && [ -e "$VALUE" ] && editor "$VALUE"

  done

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
escape_string()
{

  local type="ere"
  local s="/" #sed separator
  local q="'" #sed quote

    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Escape special characters

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-s|--sed|-g|--grep|-p|--perl|-b|--bre|-e|--ere]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

$global_help
EOF

  local ARGS=$(getopt -o "sgpbeh" -l "sed,grep,perl,bre,ere,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case $1 in
      -s|--sed) shift; type='sed';;
      -g|--grep) shift; type='grep';;
      -p|--perl) shift; type='perl';;
      -b|--bre) shift; type='perl';;
      -e|--ere) shift; type='perl';;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit $EX_OK;;
      --) shift; break;;
    esac
  done

  [ -z "$*" ] && echo "${IFS}${help}${IFS}"  >&2 && exit $EX_DATAERR;

  local path_char='\*\?\['
  local bre_char='\^\.\*\[\$\\'
  local ere_char=$bre_char'\(\)\|\+\?\{'
  local escaped_characters

  case $type in
    'sed' ) escaped_characters=$bre_char'\\'$q'\\'$s;;
    'grep' ) escaped_characters=$bre_char'\\'$q;;
    'perl' ) escaped_characters=$ere_char'\\'$q'\\'$s;;
    'bre' ) escaped_characters=$bre_char'\\'$q;;
    * ) escaped_characters=$ere_char'\\'$q;;
  esac

  for value in "$@"; do
    echo "$value" | sed -e 's'$s'['"$escaped_characters"'&]'$s'\\&'$s'g'
  done

  #;delimiter='</ \>'; printf "%s$delimiter" "${array[@]}" | sed "s/$(echo "$delimiter" | sed -e 's/['"\^\.\*\[\$\\\'\/ "'&]/\\&/g')$//"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
progress_bar()
{
  [ $# -ne 2 ] && eval "$bad_args_cmd"
  
  # http://www.utf8-chartable.de/unicode-utf8-table.pl
  local progress_char='\u25a0' # \u2588 \u25FC
  local remaining_char='\u25a1' # \u2591 \u25FB
  local number=0
  local width=20
  
    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Display a progress bar

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [--progress_char char] [--remaining_char char] [-w|--width integer] count [number] 
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

$global_help
EOF

  local ARGS=$(getopt -o "c:n:w:h" -l "count:,progress_char:,remaining_char:,number:,width:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case $1 in
      #-c|--count) shift; count=${1}; shift;;      
      --progress_char) shift; progress_char=${1:-$progress_char}; shift;;
      --progress_char) shift; progress_char=${1:-$remaining_char}; shift;;
      #-n|--number) shift; number=${1:-$number}; shift;;
      -w|--width) shift; char1=${1:-$width}; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit $EX_OK;;
      --) shift; break;;
    esac
  done  
  
  local count=$1
  shift
  local number=${1:-$number}
  shift

  local progress=$(echo "$width*(100/$count*$number)/100" | bc)
  printf "%0.s${progress_char}" $(seq 1 $progress)
  printf "%0.s${remaining_char}" $(seq 1 $(($width-$progress)))
  printf "%3d%%\r" $(echo "100/$count*$number" | bc)
  [[ $number==$count ]] && echo -ne "\033[2K"

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
____spinner()
{
  local pid=$1
  local delay=0.75
  sp='/-\|'
  printf ' '
  #while true; do
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
  #while [[ $(pgrep -u $pid) ]]; do
    printf '\b%.1s' "$sp"
    sp=${sp#?}${sp%???}
    sleep $delay
  done
  printf '\b%.1s' ""
}
spinner()
{
  local pid=$1
  local delay=0.75
  #local sp='|/-\'
  local sp='/-\|'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${sp#?}
    printf " [%c]  " "$sp"
    local sp=$temp${sp%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
lstree()
{
  ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/ /' -e 's/-/|/'
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
edit_var()
{
  local type='text'
  local file="$configuration_filename"
  local options

  read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Prompt user to edit a variable value

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-p|--prompt string] [-v|--value value] [-s|--save] [-q|--quote quote] [-f|--file filename] [-o|--option string]... [multiline|password|select|text] varname
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]
    
OPTIONS
    -v, --value
        The default value.
    -p, --prompt
        The text to append the input. Variable namer will be used by default.
    --quote
        Emclose value vith this quote type. You can use a single quote, double quote or an empty value (default).
    -f, --file
        The name of the file containing the variable definition. 
    -o, --option
        Some options for select type.
    --multiline
        Ask user to edit a multiline text.
    --password
        Ask user to type a password.
    --select
        Ask user to select a value from a list.
    --text
        Ask user to enter a string.
    -q, --quiet
        If variable already exists, use value instead prompt user.
    -s, --save
        Write value to the file.
    -h, --help
      Print this help screen and exit.
    
$global_help
EOF
  
  local ARGS=$(getopt -o "+f:hk:o:p:q:sv:" -l "+key:value:,option:,prompt:;quote:,quiet,file:,multiline,password,select,text,save,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in      
      --multiline) shift; local type='multiline';;
      --password) shift; local type='password';;
      --quote) shift; local quote=$1; shift;;
      --select) shift; local type='select';;
      --text) shift; local type='text';;
      -f|--file) shift; local file="${1:-$file}"; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit $EX_OK;;
      #-k|--key) shift; local key="$1"; local prompt=${prompt:-"$1"}; shift;;
      -o|--option) shift; type='select'; options+=("$1"); shift;;
      -p|--prompt) shift; local prompt="$1"; shift;;
      -q|--quiet) shift; local quiet=1;;
      -s|--save) shift; local save=1;;
      -v|--value) shift; local value="$1"; shift;;
      --) shift; break;;
    esac
  done

  if [ -n "$1" ]; then
    local key="$1"
    local prompt=${prompt:-"$1"}
    shift
  else
    echo "${IFS}${help}${IFS}"
    exit 1
  fi
  
  # If variable is already defined
  if [[ ${!key} ]]; then
    [[ $quiet ]] && return
    local value="${!key}"    
  fi  
  
  # Ask user answer
  # Save the new value to the configuration file if not empty
  # Or save default value
  case $type in
    'multiline' )
      read -p "$prompt :" VALUE
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" --multiline "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" --multiline "$key" "$value"
      fi
    ;;
    'password' )
      read -s -p "$prompt :" VALUE
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$value"
      fi
    ;;
    'select' )
      __menu -t "$prompt" $(printf ' -o %s' $options) --back --exit
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$value"
      fi
    ;;
    * )
      read -p "$prompt [$value]:" VALUE
      if [ -n "$save" -a -n "$file" ]; then
        [ -n "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$VALUE"
        [ -z "$VALUE" ] && __save_variable -q $quote -f "$file" "$key" "$value"
      fi
    ;;
  esac
  # Immediately activate the new value
  [ -n "$VALUE" ] && eval "${key}=${VALUE}"  

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
in_array() {
    local hay needle=$1
    shift
    for hay; do
        [[ $hay == $needle ]] && return 0
    done
    return 1
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
include_once() {
    [ $# -ne 1 ] && eval "$bad_args_cmd"
    local src
    local filename=$(readlink -f "$1")
    [ ! -e "$filename" ] && return 1    
    #local sources=($(printf "%s${IFS}" "${BASH_SOURCE[@]}" | sort -u))
    
    for src in "${sources[@]}"; do
        [[ $(readlink -f "$src") = "$filename" ]] && echo "MATCH"  >&2&& return 1
    done
    
    sources+=("$filename")
    . "$filename"
    return 0
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
translate()
{
  wget -qO- "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=$1&langpair=$2|${3:-en}" | sed 's/.*"translatedText":"\([^"]*\)".*}/\1\n/'
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
calc ()
{
  #echo $(($*))
  echo "$*" | bc -l
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__save_variable()
{

    read -d '' help <<EOF
NAME
    ${BASH_SOURCE##*/} ${FUNCNAME} - Write a variable definition in a file

SYNOPSIS
    ${BASH_SOURCE##*/} ${FUNCNAME} [-f|--file filename] [--m|--multiline] [-q|--quote] [-e|--enable] [-q|--disable] [key] [value]
    ${BASH_SOURCE##*/} ${FUNCNAME} [-h|--help]

DESCRIPTION
    Return $REPLY (the number) and $VALUE (the option text).

OPTIONS
    -f, --file
        File to write.
    -f, --file
        File to write.
    -m, --multiline
        Replace a mutiline variable definition with read -d '' varname <<EOF.
    -q, --quote
        Quote to use with value.
    -e, --enable
        Remove comment character before variable definition if present.
    -d, --disable
        Add a comment character before variable definition.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  local ARGS=$(getopt -o "f:q:medh" -l "file:,quote:,multiline,enable,disable,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -f|--file) shift; local file=$1; shift;;
      -q|--quote) shift; local quote=$1; shift;;
      -m|--multiline) shift; local multiline=1;;
      -e|--enable) shift; local enable=1;;
      -d|--disable) shift; local disable=1;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit $EX_OK;;
      --) shift; break;;
    esac
  done

  if [ -n "$1" ]; then
    local key="$1"; shift
  else
    echo "${IFS}${help}${IFS}" >&2; exit $EX_USAGE
  fi
  
  if [ -n "$1" ]; then
    local value="$1"; shift
  else
    echo "${IFS}${help}${IFS}" >&2; exit $EX_USAGE
  fi

  if [ -z "$file" ]; then
    echo "${IFS}${help}${IFS}" >&2; exit $EX_USAGE
  fi
  
  local s="/" #sed delimiters
  local q="'" #sed quotes

  [ ! -e "$file" ] && echo -e "#!/bin/bash${IFS}" > "$file"

  if [[ $multiline ]]; then
    test=$(grep -P 'read +-d +(""|'"''"') +'"$key"' *<<-?EOF' "$file")
    [ -z "$test" ] && echo -e 'read -d '"''"' '"$key"' <<EOF${IFS}EOF' >> "$file"

    sed -i -r '/read +-d +(""|'"''"') +'"$key"' *<<-?EOF/,/^EOF/{//!d}' "$file"
    while read line; do
      escaped_value=$(escape_string --sed "$line")
      sed -i -r -e '/read +-d +(""|'"''"') +'"$key"' *<<-?EOF/{:a;n;/^EOF/!ba;i'"$escaped_value" -e '}' "$file"
    done < <(echo -e $value)
  else
    test=$(grep -P '(^|;)(\h*)'"$key"'\s*=' "$file")
    [ -z "$test" ] && echo -e "$key"'=${IFS}' >> "$file"

    escaped_value=$(escape_string --sed "$quote$value$quote")
    sed -r -i 's'$s'(^|;)([ \t]*)'"$key"'\s*=.*$'$s'\1\2'"$key"'='"$escaped_value"''$s "$file"
  fi

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__get_config_value()
{

  local ARGS=$(getopt -o "+k:f:q:h" -l "+key:,file:,quote:,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -k|--key) shift; key=$1; shift;;
      -f|--file) shift; file=$1; shift;;
      -q|--quote) shift; quote=$1; shift;;
      -h|--help) shift; echo "${IFS}${help}${IFS}" >&2; exit $EX_OK;;
      --) shift; break;;
    esac
  done

  local var=$(grep -P -m 1 "(^|[;\t ]+)$key\s*=\s*" "$file")

  [ "$quote" == "'" ] && var="${var#*\'}" && var="${var%\'*}"
    [ "$quote" == '"' ] && var="${var#*\"}" && var="${var%\"*}"
    [[ ! $quote ]] && var=$(echo $var | sed -r "s|^.*$key\s*=\s*(\S*).*$|\1|")
    echo $var
  }
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
  
# Available functions:
# $(declare -F | cut -d" " -f3 | grep -v '^_.*$' | sort | sed -r 's/^(.*)/    - \1/g')

  #set -e
  #set -u
  # Check if sudo is installed
  # If you cannot authenticate with su, try sudo chmod u+s /bin/su
  if [[ $UID != 0 && ! $(id -Gn $USER | grep -wo sudo) ]]; then
    echo -e "Some commands must be run as superuser and require sudo command."
    read -n 1 -p "Do you want to install sudo (require root password) ? [yN]:" reply ; echo
    [[ $reply =~ [[=y=]] ]] && __package_cp install
  fi  
  
  #filename=$(readlink -f "$BASH_SOURCE")
  file_prefix=${BASH_SOURCE%.*}_
  #configuration_filename="${file_prefix}$(hostid).conf"
  configuration_filename="${HOME}/$(basename "${file_prefix}")$(hostid).conf"
  menu=${0#"$file_prefix"}
  menu=${menu#"$0"}
  menu=${menu%.*}

  #  Overwrite default configuration if a custom config file exists
  #+ or create the file
  if [ ! -e "$configuration_filename" ]; then
    echo "#!/bin/bash" > "$configuration_filename"
    sudo chmod 0600 "$configuration_filename"
  else
    include_once "$configuration_filename"
  fi
  
# Be sure that default variables are defined
[[ ! $BASH ]] && BASH=/bin/bash
[[ ! $HOME ]] && HOME=$(echo ~)
[[ ! $PWD ]] && PWD=$(pwd -P)
[[ ! $TMPDIR ]] && TMPDIR=/tmp
[[ ! $UID ]] && UID=$(id -u)
[[ ! $USER ]] && USER=$(whoami)

# Be sure that default aliases are defined
[[ ! $(alias -p | grep '^alias editor=') ]] && alias editor=$(sudo which nano || sudo which ed || sudo which vi)

#'editor /etc/sudoers'='visudo'

# Paths
# With ending /
# (/[a-zA-Z0-9_\.-]+)+/?
[[ ! $config_path && -d /etc ]] && config_path=/etc/
[[ ! $service_path && $(sudo which service) ]] && service_path="service "
[[ ! $service_path && -d /etc/init.d ]] && service_path=/etc/init.d/
[[ ! $service_path && $(sudo which invoke-rc.d) ]] && service_path="invoke-rc.d "

# Commands who doesn't exists on othe systems
# getent passwd <uid>
# dscl . -search /Users UniqueID <uid>

# Exit codes as define in /usr/include/sysexits.h
readonly EX_OK=0       # successful termination
#readonly EX__BASE=64      # base value for error messages
readonly EX_USAGE=64      # command line usage error
readonly EX_DATAERR=65      # data format error
readonly EX_NOINPUT=66      # cannot open input
#readonly EX_NOUSER=67      # addressee unknown
#readonly EX_NOHOST=68      # host name unknown
#readonly EX_UNAVAILABLE=69      # service unavailable
#readonly EX_SOFTWARE=70      # internal software error
#readonly EX_OSERR=71      # system error (e.g., can't fork)
#readonly EX_OSFILE=72      # critical OS file missing
#readonly EX_CANTCREAT=73      # can't create (user) output file
#readonly EX_IOERR=74      # input/output error
#readonly EX_TEMPFAIL=75      # temp failure; user is invited to retry
#readonly EX_PROTOCOL=76      # remote error in protocol
#readonly EX_NOPERM=77      # permission denied
#readonly EX_CONFIG=78      # configuration error
#readonly EX__MAX=78      # maximum listed value

# Some commands to eval
read -d '' bad_args_cmd <<EOF
echo "\${BASH_SOURCE##*/} \${FUNCNAME} line \$LINENO : Function wait for an argument."  >&2
exit \$EX_USAGE
EOF

# Some regex
varname_regex=[a-zA-Z_]+[a-zA-Z0-9_]*

# Make a list of main services
[[ $(sudo which mysql) ]] && database_servers+=('mysql')
#[[ $(sudo which postgresql) ]] && database_servers+=('postgresql')
#[[ $(sudo which rpcbind) ]] && dns_servers+=('bind9')
#[[ $(sudo which mydns) ]] && dns_servers+=('mydns')
[[ $(sudo which nfsstat) ]] && file_servers+=('nfs') # nfs / samba
[[ $(sudo which pure-ftpd-control) ]] && ftp_servers+=('pure-ftpd')
[[ $(sudo which postfix) ]] && smtp_servers+=('postfix')
#[[ $(sudo which exim4) ]] && smtp_servers+=('exim4')
#[[ $(sudo which courier) ]] && imap_servers+=('courier')
[[ $(sudo which dovecot) ]] && imap_servers+=('dovecot')
#[[ $(sudo which rpcbind) ]] && print_servers+=('bind9')
[[ $(sudo which rpcbind) ]] && ssh_servers+=('bind9')
#[[ $(sudo which apache) ]] && web_servers+=('apache')
[[ $(sudo which apache2) ]] && web_servers+=('apache2')
#[[ $(sudo which nginx) ]] && web_servers+=('nginx')
[[ $(sudo which squirrelmail-configure) ]] && webmail_apps+=('squirrelmail')
#[[ $(sudo which roundcube) ]] && webmail_apps+=('roundcube')
#[[ $(sudo which awstats) ]] && web_servers+=('awstats')
#[[ $(sudo which webalizer) ]] && web_servers+=('webalizer')
#[[ $(sudo which openvz) ]] && virtualization_servers+=('openvz')

read -d '' aliases <<'EOF'
alias clickpanic='
alias compgen-list='compgen -A "$(select v in alias arrayvar binding builtin command directory disabled enabled export file function group helptopic hostname job keyword running service setopt shopt signal stopped user variable; do [ -n "$v" ] && echo $v && break; done)"'
alias getent-indexes='getent "$(select v in ahosts ahostsv4 ahostsv6 aliases ethers group gshadow hosts initgroups netgroup networks passwd protocols rpc services shadow; do [ -n "$v" ] && echo $v && break; done)" | awk -F'"'"'[: \t]'"'"' '"'"'{print $1}'"'"' | sort | uniq'
alias reconfigure-package='dpkg-reconfigure "$(select v in $(debconf-show --listowners | sort); do [ -n "$v" ] && echo $v && break; done)"'
alias remove-alias='unalias "$(select v in $(compgen -a | sort); do [ -n "$v" ] && echo $v && break; done)"'
alias restart-service='service "$(select v in $(ls /etc/init.d/ | sort); do [ -n "$v" ] && echo $v && break; done)" restart'
alias configure-alias='update-alternatives --config "$(select v in $(update-alternatives --get-selections | awk '{print $1}' | sort); do [ -n "$v" ] && echo $v && break; done)"'
alias disable-apache-mod='a2dismod "$(select v in $(apachectl -M 2>&1 | tail -n+3 | grep -o '\S*_module' | sed 's/_module//' | sort); do [ -n "$v" ] && echo $v && break; done)" && service apache2 restart'
alias enable-apache-site='a2ensite "$(select v in $(find /etc/apache*/sites-available/ -type f -name '*.vhost' -printf "%f${IFS}" | sed 's/.vhost//' | sort); do [ -n "$v" ] && echo $v && break; done)"'
alias install-task='tasksel install "$(select v in $(tasksel --list-tasks | grep '^u' | awk '{print $2}' | sort); do [ -n "$v" ] && echo $v && break; done)"'
alias remove-task='tasksel remove "$(select v in $(tasksel --list-tasks | grep '^i' | awk '{print $2}' | sort); do [ -n "$v" ] && echo $v && break; done)"'
EOF


  if [ -n "$(sudo which curl)" ]; then
    ip=$(curl -s ifconfig.me)
    read -d '' message <<EOF
"The script has been executed from ${ip:-'an unknow IP address'} ($HOSTNAME)."
EOF
    #mail -s "$(basename $0) $@" "stats@clickpanic.com" "$message" &
  fi

  read -d '' global_help <<EOF
AUTHOR
    Written by Christophe BOISIER.

REPORTING BUGS
    Report bugs or Skype me to christophe.boisier@live.fr

COPYRIGHT
    Copyright (c) 2013 Christophe BOISIER License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
EOF

read -d '' help <<EOF
NAME
    ${0##*/} - ${script_short_description:-One more script} by CLICKPANIC

SYNOPSIS
    ${0##*/} [-c|--configure] [-i|--interactive] [--install] [--purge] [--uninstall] [-V|--version] [-h|--help]
    ${0##*/} [$(declare -F | cut -d" " -f3 | grep -v '^_.*$' | sort | tr "${IFS}" '|' | sed 's/|$//')] [arg]... [-h|--help]

DESCRIPTION
    With this script you will no longer need to remember lots of commands.
    Run it with a select menu for live operations or from a script by calling one of the included functions.

OPTIONS
    -c, --configure
        Edit the configuration file with the default editor.
    -i, --interactive
        Run script in live mode with a select menu and asking sone questions to user.
    --install
        Install completion script, aliases and other stufs in user folder.
    --purge
        Delete current configuration file.
    --uninstall
        Remove tracks of this script in user folder (exepted config file).        
    -V, --version
        Print version information and exit successfully.
    -h, --help
        Print this help screen and exit.

$global_help
EOF

  
  #[[ $# = 0 ]] && echo "${IFS}${help}${IFS}" && exit $EX_USAGE
  
  ARGS=$(getopt -o "+icVh" -l "+interactive,configure,install,purge,uninstall,version,help" -n "$0" -- "$@")
  eval set -- "$ARGS";
  while true; do
    case "$1" in
      -i|--interactive) shift; eval "__${menu:-main}_menu";;
      -c|--configure) shift; editor "$configuration_filename" < `tty` > `tty`;;
      --install) shift; __install;;
      --purge) shift; [[ -f "$configuration_filename" ]] && rm "$configuration_filename";;
      --uninstall) shift; __uninstall;;
      -V|--version) shift; echo "$script_version";;
      -h|--help) shift; echo "${IFS}${help}${IFS}"; exit $EX_OK;;
      --) shift; break;;
    esac
  done

  [[ -n "$@" ]] && eval "$@"
