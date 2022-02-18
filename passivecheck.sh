#!/bin/bash

# Opsview data
 OPSVIEW_URL='ggs-666-orc.os.opsview.com'
OPSVIEW_USER='admin'
OPSVIEW_PASS='initial'
 servicename='Dummy Check'
    hostname="$(hostname -f)"
# Default values
     comment='Service state OK.'

function usage() {
  echo -e "
  Usage: \e[1m`basename $0`\e[0m [options] command warn crit\n
       Options: -u : username
                -p : password
                -o : Opsview REST server
                -h : hostname
                -s : servicename
                -c : comment\n
       command     : Command/script to run. Must return a number.
       warn        : Warning value for the number
       crit        : Critical value for the number\n\n"
}

while true; do
  case "$1" in
    --help ) usage; exit ;;
    -o ) shift; OPSVIEW_URL="$1" ;;
    -u ) shift; OPSVIEW_USER="$1" ;;
    -p ) shift; OPSVIEW_PASS="$1" ;;
    -h ) shift; hostname="$1" ;;
    -s ) shift; servicename="$1" ;;
    -c ) shift; comment="$1" ;;
    *  ) break ;;
  esac
  shift
done

if [[ $# -eq 3 ]]; then
  metric_command="$1"
  warn="$2"
  crit="$3"
else
  usage
  exit
fi

errfile=$(mktemp /tmp/err.XXX)
value="$(eval "$metric_command" 2>$errfile)"
ret=$?
if [[ $ret -eq 0 ]]; then
  if [[ ! $value =~ [0-9][0-9]* ]]; then
    value=0
    new_state=3 # UNKNOWN
    comment="\"$metric_command\" should return a number."
  elif [[ $value -lt $warn ]]; then
    new_state=0 # OK
  elif [[ $value -lt $crit ]]; then
    new_state=1 # WARN
  else
    new_state=2 # CRIT
  fi
else
  value=0
  new_state=3 # UNKNOWN
  comment=$(cat $errfile)
fi
rm -f $errfile

function urlencode() {
  echo -n "$1" | sed "s/%/%25/g; s/ /%20/g; s/\!/%21/g; s/\"/%22/g; s/\#/%23/g; s/\\$/%24/g;
   s/\&/%26/g; s/'/%27/g; s/(/%28/g; s/)/%29/g; s/*/%2A/g; s/\+/%2B/g; s/\,/%2C/g; s/-/%2D/g;
   s/\./%2E/g; s/\//%2F/g; s/\:/%3A/g; s/\;/%3B/g; s/</%3C/g; s/\=/%3D/g; s/>/%3E/g; s/\?/%3F/g;
   s/\@/%40/g; s/\[/%5B/g; s/\\\/%5C/g; s/\]/%5D/g; s/\^/%5E/g; s/\_/%5F/g; s/\`/%60/g; s/{/%7B/g;
   s/|/%7C/g; s/\}/%7D/g; s/\~/%7E/g;" | tr '\n' '#' | sed 's/#/%0A/g'
}

perfdata="value=$value"
checkdata="servicename=$(urlencode "$servicename")&hostname=$(urlencode "$hostname")&new_state=$(urlencode "$new_state")&comment=$(urlencode "$comment")|$(urlencode "$perfdata")"

token=$(curl -ksL -H 'Content-Type: application/json' -X 'application/json' -X POST -d '{"username":"'$OPSVIEW_USER'","password":"'$OPSVIEW_PASS'"}' "https://$OPSVIEW_URL/rest/login" | egrep -o '[0-9a-f]{32}')
curl -kL -H "Content-Type: application/json" -H "Accept: application/json" -X POST -H "X-Opsview-Token: $token" -d "{}" "http://$OPSVIEW_URL/rest/status?$checkdata"
curl -ksL -H 'Content-Type: application/json' -H "X-Opsview-Token: $token" -X 'application/json' -X POST "https://$OPSVIEW_URL/rest/logout" &>/dev/null
exit
